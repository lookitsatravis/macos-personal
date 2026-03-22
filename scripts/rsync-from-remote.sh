#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: rsync-from-remote.sh [options] MANIFEST

Read MANIFEST (one absolute remote path per line; blank lines and # comments ignored)
and rsync each path from USER@HOST over SSH to the same absolute path locally,
unless --map rewrites the local prefix or --dest-root places that layout under a directory.

SSH passwords are not accepted as flags; use SSH keys or type the password when ssh prompts.

Paths with spaces or shell metacharacters need rsync with --protect-args (GNU rsync).
Set RSYNC to a GNU rsync binary if needed (e.g. brew install rsync, then RSYNC=/opt/homebrew/opt/rsync/bin/rsync).

Options:
  -H, --host HOST              Remote hostname or IP (else prompted)
  -u, --user USER              SSH username (else prompted)
  -p, --port PORT              SSH port (default 22; else prompted if omitted)
  --map REMOTE_PREFIX:LOCAL_PREFIX
                               If a manifest path equals REMOTE_PREFIX or is under it,
                               replace that prefix with LOCAL_PREFIX for the local path
  --dest-root DIR              After --map (if any), write under DIR using the same
                               relative layout (e.g. /Users/a/P -> DIR/Users/a/P).
                               Omit for default: use the computed absolute path as-is.
  -n, --dry-run                Pass --dry-run to rsync
  -h, --help                   Show this help
EOF
    exit "${1:-0}"
}

HOST=""
USER_NAME=""
PORT="22"
PORT_EXPLICIT=0
MAP_REMOTE=""
MAP_LOCAL=""
DRY_RUN=0
DEST_ROOT=""
MANIFEST=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage 0
            ;;
        -H | --host)
            HOST="${2:?}"
            shift 2
            ;;
        -u | --user)
            USER_NAME="${2:?}"
            shift 2
            ;;
        -p | --port)
            PORT="${2:?}"
            PORT_EXPLICIT=1
            shift 2
            ;;
        --map)
            map_arg="${2:?}"
            if [[ "$map_arg" != *:* ]]; then
                echo "error: --map must be REMOTE_PREFIX:LOCAL_PREFIX" >&2
                exit 1
            fi
            MAP_REMOTE="${map_arg%%:*}"
            MAP_LOCAL="${map_arg#*:}"
            if [[ -z "$MAP_REMOTE" || -z "$MAP_LOCAL" ]]; then
                echo "error: --map must use non-empty REMOTE_PREFIX and LOCAL_PREFIX" >&2
                exit 1
            fi
            shift 2
            ;;
        --dest-root)
            DEST_ROOT="${2:?}"
            shift 2
            ;;
        -n | --dry-run)
            DRY_RUN=1
            shift
            ;;
        -*)
            echo "error: unknown option: $1" >&2
            usage 1
            ;;
        *)
            if [[ -n "$MANIFEST" ]]; then
                echo "error: unexpected argument: $1" >&2
                usage 1
            fi
            MANIFEST="$1"
            shift
            ;;
    esac
done

if [[ -z "$MANIFEST" ]]; then
    echo "error: manifest file path is required" >&2
    usage 1
fi

if [[ ! -f "$MANIFEST" ]] || [[ ! -r "$MANIFEST" ]]; then
    echo "error: manifest not found or not readable: $MANIFEST" >&2
    exit 1
fi

if [[ -z "$HOST" ]]; then
    read -r -p "Remote host (hostname or IP): " HOST
fi
if [[ -z "$HOST" ]]; then
    echo "error: host is required" >&2
    exit 1
fi

if [[ -z "$USER_NAME" ]]; then
    read -r -p "SSH username: " USER_NAME
fi
if [[ -z "$USER_NAME" ]]; then
    echo "error: username is required" >&2
    exit 1
fi

if [[ "$PORT_EXPLICIT" -eq 0 ]]; then
    read -r -p "SSH port [22]: " port_input
    if [[ -n "${port_input:-}" ]]; then
        PORT="$port_input"
    fi
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1 ]] || [[ "$PORT" -gt 65535 ]]; then
    echo "error: invalid port: $PORT" >&2
    exit 1
fi

if [[ "$PORT" == "22" ]]; then
    RSYNC_E="ssh"
else
    RSYNC_E="ssh -p $PORT"
fi

# Prefer GNU rsync when present so --protect-args keeps remote paths with spaces/special
# chars from being split by the remote shell. Apple openrsync does not support it.
pick_rsync_bin() {
    local c h
    if [[ -n "${RSYNC:-}" ]]; then
        printf '%s\n' "$RSYNC"
        return
    fi
    for c in /opt/homebrew/opt/rsync/bin/rsync /usr/local/opt/rsync/bin/rsync; do
        [[ -x "$c" ]] || continue
        h="$("$c" --help 2>&1)" || continue
        if [[ "$h" == *protect-args* || "$h" == *separate-args* ]]; then
            printf '%s\n' "$c"
            return
        fi
    done
    command -v rsync
}

rsync_supports_protect_args() {
    local h
    h="$("$1" --help 2>&1)" || return 1
    [[ "$h" == *protect-args* || "$h" == *separate-args* ]]
}

RSYNC_BIN="$(pick_rsync_bin)"
RSYNC_EXTRA=()
if rsync_supports_protect_args "$RSYNC_BIN"; then
    RSYNC_EXTRA+=(--protect-args)
else
    echo "warning: $RSYNC_BIN has no --protect-args; paths with spaces or shell metacharacters may fail." >&2
    echo "warning: install GNU rsync (brew install rsync) or set RSYNC to its binary." >&2
fi

map_to_local() {
    local remote_path="$1"
    if [[ -n "$MAP_REMOTE" ]]; then
        if [[ "$remote_path" == "$MAP_REMOTE" ]]; then
            printf '%s\n' "$MAP_LOCAL"
            return
        fi
        if [[ "$remote_path" == "$MAP_REMOTE/"* ]]; then
            local rest="${remote_path#"$MAP_REMOTE"/}"
            printf '%s\n' "${MAP_LOCAL%/}/$rest"
            return
        fi
    fi
    printf '%s\n' "$remote_path"
}

line_num=0
while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    trimmed="${line#"${line%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    [[ -z "$trimmed" ]] && continue
    [[ "$trimmed" == \#* ]] && continue

    remote_path="$trimmed"
    if [[ "$remote_path" == *$'\n'* || "$remote_path" == *$'\r'* ]]; then
        echo "error: line $line_num: path must not contain newline or carriage return" >&2
        exit 1
    fi
    if [[ "$remote_path" != /* ]]; then
        echo "error: line $line_num: path must be absolute (start with /): $remote_path" >&2
        exit 1
    fi

    local_path="$(map_to_local "$remote_path")"
    if [[ -z "$local_path" ]]; then
        echo "error: line $line_num: mapped local path is empty" >&2
        exit 1
    fi
    if [[ "$local_path" != /* ]]; then
        echo "error: line $line_num: mapped local path must be absolute: $local_path" >&2
        exit 1
    fi

    if [[ -n "$DEST_ROOT" ]]; then
        local_path="${DEST_ROOT%/}/${local_path#/}"
    fi
    if [[ -z "$local_path" ]]; then
        echo "error: line $line_num: local path is empty after --dest-root" >&2
        exit 1
    fi

    local_parent="$(dirname "$local_path")"
    mkdir -p "$local_parent"

    # Build user@host:path as one module string without embedding $remote_path in one
    # double-quoted expansion (so embedded " in paths cannot break the shell word).
    remote_spec="${USER_NAME}@${HOST}:"
    remote_spec+="${remote_path}"

    echo "==> $remote_path -> $local_path" >&2
    if [[ "$DRY_RUN" -eq 1 ]]; then
        "$RSYNC_BIN" "${RSYNC_EXTRA[@]}" -avhP --dry-run -e "$RSYNC_E" -- "$remote_spec" "${local_parent}/"
    else
        "$RSYNC_BIN" "${RSYNC_EXTRA[@]}" -avhP -e "$RSYNC_E" -- "$remote_spec" "${local_parent}/"
    fi
done <"$MANIFEST"
