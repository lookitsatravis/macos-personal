#! /usr/bin/env bash

# Check if devbox is already installed in the PATH
if ! command -v devbox &> /dev/null; then
    echo -e "${ARROW}Installing devbox..."
    curl -fsSL https://get.jetify.com/devbox | bash
    echo -e "${ARROW}devbox installed!"
else
    echo -e "${ARROW}devbox is already installed!"
fi
