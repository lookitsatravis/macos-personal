#! /usr/bin/env bash

# Restore dotfiles
echo -e "${ARROW}Restoring dotfiles..."
rsync -ax ${BACKUP_DIR}/.config $HOME

for dotfile in "${DOTFILES[@]}"; do
    echo -e "${ARROW}Restoring $dotfile..."

    # if entry is a directory, copy recursively
    if [ -d $BACKUP_DIR/$dotfile ]; then
        cp -r $BACKUP_DIR/$dotfile ~/
        continue
    fi

    mkdir -p "$(dirname "$HOME/$dotfile")"
    cp -f "$BACKUP_DIR/$dotfile" "$HOME/$dotfile"
done

# Developer folder for projects
echo -e "${ARROW}Creating projects folder..."
mkdir -p $HOME/Documents/Projects
