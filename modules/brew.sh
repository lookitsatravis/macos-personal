#! /usr/bin/env bash

# Resolve the Homebrew binary (Apple Silicon vs Intel).
brew_bin_path() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        echo /opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
        echo /usr/local/bin/brew
    fi
}

# Brew install and setup
if [[ -z "$(brew_bin_path)" ]]; then
    echo -e "${ARROW}Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo -e "${ARROW}Homebrew installed!"
else
    echo -e "${ARROW}Homebrew is already installed!"
fi

BREW_BIN=$(brew_bin_path)
if [[ -z "$BREW_BIN" ]]; then
    echo -e "${RED}Error.${RESET} Homebrew not found under /opt/homebrew or /usr/local after install."
    exit 1
fi

eval "$("$BREW_BIN" shellenv)"

# Disables brew telemetry
echo -e "${ARROW}Disabling Homebrew telemetry..."
brew analytics off

# Brew Apps installed from Brewfile
echo -e "${ARROW}Installing apps..."
brew bundle install --file $BACKUP_DIR/Brewfile
