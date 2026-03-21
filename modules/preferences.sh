#! /usr/bin/env bash

echo -e "${ARROW}Changing macOS defaults..."

# ------------------------------ Dock ------------------------------
# Autohide
defaults write com.apple.dock "autohide" -bool "true"
# Disable recents
defaults write com.apple.dock "show-recents" -bool "false"

# ------------------------------ Finder ------------------------------
# Show file extensions
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"
# Show hidden files
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"
# Show path bar
defaults write com.apple.finder "ShowPathbar" -bool "true"
# List view
defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"
# Keep folders on top
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"
defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool "true"
# Search scope current folder
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"

# ------------------------------ Spaces ------------------------------
# Groups windows by application on mission control
defaults write com.apple.dock expose-group-apps -bool true

killall Dock && killall Finder
