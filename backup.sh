#! /usr/bin/env bash

# Variables and directory check 
source init.sh
source modules/nonbrew-apps.sh

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

# Removes unused dotfiles
echo -e "${ARROW}Removing previous backup..."
rm -rf $BACKUP_DIR
rm -rf $SOPS_DIR

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

for sops in "${SOPS[@]}"; do
    src="$HOME/$sops"
    if [[ -d "$src" ]]; then
        echo -e "${ARROW}Encrypting directory $sops..."
        find "$src" -type f ! -name '.DS_Store' -print0 | while IFS= read -r -d '' f; do
            rel="${f#"$HOME"/}"
            out="$SOPS_DIR/$rel.enc"
            mkdir -p "$(dirname "$out")"
            echo -e "${ARROW}  -> $rel"
            sops -e --age "$SOPS_AGE_RECIPIENT" "$f" >"$out"
        done
    elif [[ -f "$src" ]]; then
        echo -e "${ARROW}Encrypting $sops..."
        mkdir -p "$(dirname "$SOPS_DIR/$sops")"
        sops -e --age "$SOPS_AGE_RECIPIENT" "$src" >"$SOPS_DIR/$sops.enc"
    else
        echo -e "${YELLOW}Skipping SOPS (missing): ${sops}${RESET}"
    fi
done

# Backs up currently installed brew packages, -f overrides current file
echo -e "${ARROW}Creating Brewfile..."
brew bundle dump -v -f --file $BACKUP_DIR/Brewfile

echo -e "${ARROW}Recording non-Homebrew applications..."
record_nonbrew_applications "$BACKUP_DIR/nonbrew-applications.txt"

echo -e "${GREEN}Done!${RESET}"
