#! /usr/bin/env bash

FORCE_SOPS=0
INIT_SOPS_REGISTRY=0
parsed_args=()
for arg in "$@"; do
    case "$arg" in
        --force-sops) FORCE_SOPS=1 ;;
        --init-sops-registry) INIT_SOPS_REGISTRY=1 ;;
        *) parsed_args+=("$arg") ;;
    esac
done
set -- "${parsed_args[@]}"

# Variables and directory check
source init.sh
source modules/nonbrew-apps.sh

SOPS_REGISTRY="$SOPS_DIR/.plaintext-sha256"

plaintext_hash() {
    shasum -a 256 <"$1" | awk '{print $1}'
}

registry_get() {
    local rel="$1"
    [[ -f "$SOPS_REGISTRY" ]] || return 1
    REL="$rel" awk -F '\t' '$1 == ENVIRON["REL"] {print $2; exit}' "$SOPS_REGISTRY"
}

SOPS_REGISTRY_LINES=()

record_registry_line() {
    SOPS_REGISTRY_LINES+=("${1}	${2}")
}

write_sops_registry() {
    mkdir -p "$SOPS_DIR"
    local tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/sops-registry.XXXXXX")
    if ((${#SOPS_REGISTRY_LINES[@]} > 0)); then
        printf '%s\n' "${SOPS_REGISTRY_LINES[@]}" | LC_ALL=C sort -t $'\t' -k1,1 >"$tmp"
    else
        : >"$tmp"
    fi
    mv "$tmp" "$SOPS_REGISTRY"
}

# Walk SOPS paths; invoke callback with (absolute_file_path, rel_under_home).
__sops_each_source_file() {
    local callback="$1"
    for sops in "${SOPS[@]}"; do
        local src="$HOME/$sops"
        if [[ -d "$src" ]]; then
            echo -e "${ARROW}SOPS directory $sops..."
            local f rel
            while IFS= read -r -d '' f; do
                rel="${f#"$HOME"/}"
                "$callback" "$f" "$rel"
            done < <(find "$src" -type f ! -name '.DS_Store' -print0)
        elif [[ -f "$src" ]]; then
            echo -e "${ARROW}SOPS file $sops..."
            "$callback" "$src" "$sops"
        else
            echo -e "${YELLOW}Skipping SOPS (missing): ${sops}${RESET}"
        fi
    done
}

_sops_init_record_hash() {
    local f="$1" rel="$2"
    echo -e "${ARROW}  -> $rel"
    record_registry_line "$rel" "$(plaintext_hash "$f")"
}

if [[ "$INIT_SOPS_REGISTRY" -eq 1 ]]; then
    echo -e "${ARROW}Initializing SOPS plaintext hash registry (no encrypt, no full backup)..."
    SOPS_REGISTRY_LINES=()
    __sops_each_source_file _sops_init_record_hash
    write_sops_registry
    echo -e "${GREEN}Wrote $SOPS_REGISTRY (${#SOPS_REGISTRY_LINES[@]} paths).${RESET}"
    exit 0
fi

# ~/.config rsync excludes — paths are relative to ~/.config (see rsync(1) --exclude).
# Kept by default: dev CLI/editor config (nvim, gh, git, graphite, op, devbox, valet,
# heroku, tabtab, inngest, etc.). Add patterns here when something is machine-local,
# a reinstallable cache, or not worth versioning.
CONFIG_RSYNC_EXCLUDES=(
    ".DS_Store"
    "gcloud"
    "iterm2"
    # Logs and git metadata anywhere under ~/.config
    "*.log"
    ".git"
    "*.git"
    # Vendor / app-specific — not portable dotfiles. (Name is literally "Microsoft\VisualStudio Services".)
    'Microsoft\VisualStudio Services'
    "Webull Desktop"
    "Unreal Engine"
    "com.corsair"
    "sonic-pi.net"
    "stetic"
    "yarn"
    # configstore: npm/CLI update-notifier state + firebase-tools tokens (secrets).
    "configstore"
    # CLI dirs that cache auth tokens / API keys — encrypt via SOPS or exclude.
    "heroku"
    "graphite"
    "op"
    ".mono"
    # nvim: runtime needs init.lua + lua/** only. (.git already excluded above.)
    "nvim/.github"
    "nvim/LICENSE"
    "nvim/.typos.toml"
    "nvim/.stylua.toml"
    "nvim/.styluaignore"
    "nvim/.luacheckrc"
    "nvim/config.ld"
)

# Removes unused dotfiles (sops/ is kept incremental — see sops/.plaintext-sha256).
echo -e "${ARROW}Removing previous backup..."
rm -rf $BACKUP_DIR

# Creates backup directory
echo -e "${ARROW}Creating backup directory..."
mkdir -p $BACKUP_DIR
mkdir -p $SOPS_DIR

echo -e "${ARROW}Backing up dotfiles..."
rsync_args=(-ax)
for pattern in "${CONFIG_RSYNC_EXCLUDES[@]}"; do
    [[ -z "${pattern// }" ]] && continue
    rsync_args+=(--exclude="$pattern")
done
rsync "${rsync_args[@]}" ~/.config "$BACKUP_DIR/"

for dotfile in "${DOTFILES[@]}"; do
    echo -e "${ARROW}Backing up $dotfile..."

    # if entry is a directory, copy recursively (omit Finder metadata)
    if [ -d "$HOME/$dotfile" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR/$dotfile")"
        rsync -ax --exclude='.DS_Store' "$HOME/$dotfile/" "$BACKUP_DIR/$dotfile/"
        continue
    fi

    mkdir -p "$(dirname "$BACKUP_DIR/$dotfile")"
    cp -f "$HOME/$dotfile" "$BACKUP_DIR/$dotfile"
done

# Cursor's .gitignore uses '*' without un-ignoring argv.json / .gitignore, so Git would
# skip them on clone. Re-append negations after copy from $HOME (idempotent).
if [[ -f "$BACKUP_DIR/.cursor/.gitignore" ]]; then
    grep -qxF '!.gitignore' "$BACKUP_DIR/.cursor/.gitignore" || echo '!.gitignore' >>"$BACKUP_DIR/.cursor/.gitignore"
    grep -qxF '!argv.json' "$BACKUP_DIR/.cursor/.gitignore" || echo '!argv.json' >>"$BACKUP_DIR/.cursor/.gitignore"
fi

if [[ -n "${SOPS_AGE_RECIPIENT:-}" ]]; then
    echo -e "${ARROW}Using age recipient from init.sh (SOPS_AGE_RECIPIENT)."
else
    SOPS_AGE_RECIPIENT=$(op read "$SOPS_AGE_KEY_RECIPIENT_PATH")
    if [[ -z "$SOPS_AGE_RECIPIENT" ]]; then
        echo -e "${RED}Error.${RESET} Set SOPS_AGE_RECIPIENT in init.sh to your age1… key, or store it in 1Password and fix SOPS_AGE_KEY_RECIPIENT_PATH (tried $SOPS_AGE_KEY_RECIPIENT_PATH)."
        exit 1
    fi
    echo -e "${ARROW}Using age recipient from 1Password ($SOPS_AGE_KEY_RECIPIENT_PATH)."
fi
export SOPS_AGE_RECIPIENT
# Encrypt uses only the recipient; an empty SOPS_AGE_KEY can make sops ignore --age.
unset SOPS_AGE_KEY

_sops_encrypt_or_skip() {
    local f="$1" rel="$2"
    local out="$SOPS_DIR/${rel}.enc"
    mkdir -p "$(dirname "$out")"
    local current stored
    current=$(plaintext_hash "$f")
    stored=$(registry_get "$rel" || true)
    if [[ "$FORCE_SOPS" -eq 1 ]] || [[ -z "${stored:-}" ]] || [[ "$current" != "$stored" ]] || [[ ! -f "$out" ]]; then
        echo -e "${ARROW}  -> $rel"
        if ! sops -e --age "$SOPS_AGE_RECIPIENT" "$f" >"$out"; then
            rm -f "$out"
            echo -e "${RED}Error.${RESET} sops encrypt failed for $rel"
            exit 1
        fi
    else
        echo -e "${ARROW}  (unchanged) $rel"
    fi
    record_registry_line "$rel" "$current"
}

echo -e "${ARROW}Encrypting SOPS paths (plaintext hash registry: $SOPS_REGISTRY)..."
SOPS_REGISTRY_LINES=()
__sops_each_source_file _sops_encrypt_or_skip
write_sops_registry

# Backs up currently installed brew packages, -f overrides current file
echo -e "${ARROW}Creating Brewfile..."
brew bundle dump -v -f --file $BACKUP_DIR/Brewfile

echo -e "${ARROW}Recording non-Homebrew applications..."
record_nonbrew_applications "$BACKUP_DIR/nonbrew-applications.txt"

echo -e "${GREEN}Done!${RESET}"
