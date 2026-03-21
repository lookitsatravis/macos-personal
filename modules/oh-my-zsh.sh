#! /usr/bin/env bash

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${ARROW}Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo -e "${ARROW}oh-my-zsh installed!"
else
    echo -e "${ARROW}oh-my-zsh is already installed!"
fi

p10kdir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
if [ ! -d "$p10kdir" ]; then
    echo -e "${ARROW}Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $p10kdir
    echo -e "${ARROW}Powerlevel10k installed!"
else
    echo -e "${ARROW}Powerlevel10k is already installed!"
fi
