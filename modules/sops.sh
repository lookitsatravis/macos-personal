#! /usr/bin/env bash

# prompt to ensure that  1password has been setup and authenticated
echo "Please ensure that 1password has been setup and authenticated."
read -p "Press enter to continue..."

chmod 700 ~/.config/op
chmod 600 ~/.config/op/config

SOPS_AGE_KEY=$(op read "$SOPS_AGE_KEY_PASSWORD_PATH")
if [[ -z "$SOPS_AGE_KEY" ]]; then
    echo -e "${RED}Error.${RESET} Could not read age secret key from 1Password ($SOPS_AGE_KEY_PASSWORD_PATH)."
    exit 1
fi
export SOPS_AGE_KEY

for sops in "${SOPS[@]}"; do
    enc_root="$SOPS_DIR/$sops"
    if [[ -d "$enc_root" ]]; then
        echo -e "${ARROW}Decrypting directory $sops..."
        mkdir -p "$HOME/$sops"
        find "$enc_root" -type f -name '*.enc' -print0 | while IFS= read -r -d '' encf; do
            rel="${encf#"$SOPS_DIR"/}"
            target="${HOME}/${rel%.enc}"
            mkdir -p "$(dirname "$target")"
            echo -e "${ARROW}  -> ${rel%.enc}"
            sops -d "$encf" >"$target"
            chmod 600 "$target"
        done
    elif [[ -f "$SOPS_DIR/$sops.enc" ]]; then
        echo -e "${ARROW}Decrypting $sops..."
        mkdir -p "$HOME/$(dirname "$sops")"
        sops -d "$SOPS_DIR/$sops.enc" >"$HOME/$sops"
        chmod 600 "$HOME/$sops"
    else
        echo -e "${YELLOW}Skipping SOPS (no ciphertext): ${sops}${RESET}"
    fi
done