#! /usr/bin/env bash

# Brew install and setup
if ! command -v /opt/homebrew/bin/brew &> /dev/null; then
    echo -e "${ARROW}Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo -e "${ARROW}Homebrew installed!"
else
    echo -e "${ARROW}Homebrew is already installed!"
fi

# Enables brew in current env
eval "$(/opt/homebrew/bin/brew shellenv)"

# Disables brew telemetry
echo -e "${ARROW}Disabling Homebrew telemetry..."
brew analytics off

# Brew Apps installed from Brewfile
echo -e "${ARROW}Installing apps..."
brew bundle install --file $BACKUP_DIR/Brewfile
