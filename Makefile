# Run backup/restore from repo root regardless of caller cwd.
# Plain `make` runs the first target; that is `help`, not backup.
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Recipes run under /bin/sh and do not load login shells, so PATH often lacks Homebrew
# even when restore added it to ~/.zprofile. Prepend standard install locations.
export PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)

.PHONY: help backup restore brew-cleanup

help:
	@echo "Targets:"
	@echo "  make backup        - refresh backup/ and sops/"
	@echo "  make restore       - bootstrap this Mac from backup"
	@echo "  make brew-cleanup  - uninstall Homebrew formulae/casks not listed in backup/Brewfile (--force)"

backup:
	@cd "$(ROOT)" && ./backup.sh

restore:
	@cd "$(ROOT)" && ./restore.sh

brew-cleanup:
	@cd "$(ROOT)" && brew bundle cleanup --force --file="$(ROOT)backup/Brewfile"
