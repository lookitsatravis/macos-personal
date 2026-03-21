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

    # if entry is nested in a directory, create directory and copy
    if [ ! -d $(dirname $HOME/$dotfile) ]; then
        mkdir -p $(dirname $HOME/$dotfile)
    fi

    cp -f $BACKUP_DIR/$dotfile ~/$dotfile
done

# Developer folder for projects
echo -e "${ARROW}Creating projects folder..."
mkdir -p $HOME/Documents/Projects
