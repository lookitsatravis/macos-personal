# Homebrew for login shells (Terminal.app login zsh, SSH, etc.). Non-login shells read
# ~/.zshrc, which includes the same logic — keep these blocks in sync if you change one.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
