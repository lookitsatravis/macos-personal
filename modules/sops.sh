#! /usr/bin/env bash

# prompt to ensure that  1password has been setup and authenticated
echo "Please ensure that 1password has been setup and authenticated."
read -p "Press enter to continue..."

mkdir -p ~/.config/op
chmod 700 ~/.config/op
# Created by `op` after sign-in; may not exist until first successful CLI use.
[[ -f ~/.config/op/config ]] && chmod 600 ~/.config/op/config

# Ciphertext is always JSON (sops -e output), but paths end in .enc so sops would
# infer binary and fail. Match output format to the restored plaintext path.
_sops_output_type_for() {
    case "$1" in
        *.json) echo json ;;
        *.yaml | *.yml) echo yaml ;;
        *) echo binary ;;
    esac
}

_sops_decrypt_to() {
    local encf="$1" target="$2"
    local out_type
    out_type=$(_sops_output_type_for "$target")
    sops -d --input-type json --output-type "$out_type" "$encf" >"$target"
}

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
            _sops_decrypt_to "$encf" "$target"
            chmod 600 "$target"
        done
    elif [[ -f "$SOPS_DIR/$sops.enc" ]]; then
        echo -e "${ARROW}Decrypting $sops..."
        mkdir -p "$HOME/$(dirname "$sops")"
        _sops_decrypt_to "$SOPS_DIR/$sops.enc" "$HOME/$sops"
        chmod 600 "$HOME/$sops"
    else
        echo -e "${YELLOW}Skipping SOPS (no ciphertext): ${sops}${RESET}"
    fi
done