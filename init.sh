#! /usr/bin/env bash

# Color variables
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
RESET='\033[0m'

# Indicator for new sections
ARROW="${MAGENTA}==> ${RESET}"

# Path Variables
# Path for all backups
BACKUP_DIR="./backup"
SOPS_DIR="./sops"

# Path for macOS Preferences
PREFERENCES_DIR="$HOME/Library/Preferences"

# Path for current script
SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

# Dotfiles to backup
DOTFILES=(
    "bin"
    ".aliases"
    ".cursor/.gitignore"
    ".cursor/argv.json"
    ".cursor/skills-cursor"
    ".gitconfig"
    ".p10k.zsh"
    ".zshrc"
)

# Files and directories (recursive; every file under a dir is encrypted separately).
# Quote paths that contain shell glob characters (e.g. a literal '*' in the directory name).
SOPS=(
    ".acme.sh/vignon.family"
    '.acme.sh/*.vignon.family'
    ".claude.json"
    ".cursor/mcp.json"  
    ".docker/config.json"
    ".kube/config"
    ".netrc"
    ".ssh"
    ".secrets"
    ".zsh_history"
)

# Age keys for sops:
# - Encrypt: set SOPS_AGE_RECIPIENT to your age1… public key, OR leave it empty and backup.sh will
#   op read SOPS_AGE_KEY_RECIPIENT_PATH (e.g. 1Password "username" if you store the public key there).
# - Decrypt: modules/sops.sh reads the secret key from SOPS_AGE_KEY_PASSWORD_PATH only.
SOPS_AGE_RECIPIENT=""
SOPS_AGE_KEY_RECIPIENT_PATH="op://Private/AGE Key/username"
SOPS_AGE_KEY_PASSWORD_PATH="op://Private/AGE Key/password"

# Checks if current directory is correct, otherwise there will be issues with relative paths
if [ $PWD != "$SCRIPT_DIR" ]; then
    echo -e "${RED}Error.${RESET} The script must be executed from the directory $SCRIPT_DIR"
    echo "To change the directory run 'cd $SCRIPT_DIR'"
    exit 1
fi
