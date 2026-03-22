# Run backup/restore from repo root regardless of caller cwd.
# Plain `make` runs the first target; that is `help`, not backup.
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Recipes run under /bin/sh and do not load login shells, so PATH often lacks Homebrew
# even when restore added it to ~/.zprofile. Prepend standard install locations.
export PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)

.PHONY: help backup restore brew-install brew-cleanup rsync-pull

help:
	@echo "Targets:"
	@echo "  make backup        - refresh backup/ and sops/"
	@echo "  make restore       - bootstrap this Mac from backup"
	@echo "  make brew-install  - brew bundle install from backup/Brewfile only"
	@echo "  make brew-cleanup  - uninstall Homebrew formulae/casks not listed in backup/Brewfile (--force)"
	@echo "  make rsync-pull MANIFEST=path/to/file [RSYNC_ARGS=...] - pull absolute paths over SSH (see scripts/rsync-from-remote.sh --help)"

backup:
	@cd "$(ROOT)" && ./backup.sh

restore:
	@cd "$(ROOT)" && ./restore.sh

brew-install:
	@cd "$(ROOT)" && brew bundle install --file="$(ROOT)backup/Brewfile"

brew-cleanup:
	@cd "$(ROOT)" && brew bundle cleanup --force --file="$(ROOT)backup/Brewfile"

rsync-pull:
	@test -n "$(MANIFEST)" || (echo "error: set MANIFEST=path/to/manifest file" >&2; exit 1)
	@cd "$(ROOT)" && ./scripts/rsync-from-remote.sh $(RSYNC_ARGS) "$(MANIFEST)"
