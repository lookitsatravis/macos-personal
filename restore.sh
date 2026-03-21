#! /usr/bin/env bash

# Variables and directory check
source init.sh
source modules/nonbrew-apps.sh

# Installs oh-my-zsh
source modules/oh-my-zsh.sh

# Restores config files backed up
source modules/configs.sh

# Installs brew and packages from Brewfile
# You can update the Brewfile by creating your own backup (bash backup.sh) or manually
source modules/brew.sh

# Changes defaults macOS preferences
source modules/preferences.sh

# Installs devbox
source modules/devbox.sh

# Restore sops files
source modules/sops.sh

show_nonbrew_applications

echo "Next steps: Restart terminal to update shell changes."
