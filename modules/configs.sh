#! /usr/bin/env bash

# Restore dotfiles
echo -e "${ARROW}Restoring dotfiles..."
rsync -ax ${BACKUP_DIR}/.config $HOME

for dotfile in "${DOTFILES[@]}"; do
    echo -e "${ARROW}Restoring $dotfile..."

    if [[ ! -e "$BACKUP_DIR/$dotfile" ]]; then
        echo -e "${YELLOW}Skipping (not in backup): $dotfile${RESET}"
        continue
    fi

    # Directory: merge into $HOME like backup.sh (trailing slashes). Using cp -R would nest
    # (e.g. ~/bin/bin) if the destination dir already exists — common on macOS/BSD.
    if [[ -d "$BACKUP_DIR/$dotfile" ]]; then
        mkdir -p "$(dirname "$HOME/$dotfile")"
        mkdir -p "$HOME/$dotfile"
        rsync -ax --exclude='.DS_Store' "$BACKUP_DIR/$dotfile/" "$HOME/$dotfile/"
        continue
    fi

    mkdir -p "$(dirname "$HOME/$dotfile")"
    cp -f "$BACKUP_DIR/$dotfile" "$HOME/$dotfile"
done

# Developer folder for projects
echo -e "${ARROW}Creating projects folder..."
mkdir -p $HOME/Documents/Projects
