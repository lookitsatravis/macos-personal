# macOS personal setup

Opinionated shell scripts to back up dotfiles and secrets to this repo and to bootstrap a new Mac from it.

**Keep this repository private.** It contains SOPS-encrypted material that is still sensitive, plus plaintext config that can reveal hosts, tooling, and habits after restore.

## What gets backed up

Configuration lives in **`init.sh`** (sourced by **`backup.sh`** and **`restore.sh`**).

- **`DOTFILES`** — copied into **`backup/`** (files and directories under `$HOME`).
- **`~/.config`** — rsync’d into **`backup/.config/`**, with excludes listed in **`backup.sh`** (`CONFIG_RSYNC_EXCLUDES`).
- **`SOPS`** — each path under `$HOME` is encrypted with [SOPS](https://github.com/getsops/sops) + age into **`sops/`** (single files as `path.enc`; directories are one `.enc` per file, mirroring the tree).
- **`backup/nonbrew-applications.txt`** — paths of **`.app`** bundles in **`/Applications`** and **`~/Applications`** that do not resolve under Homebrew **Caskroom/Cellar** and are not **`com.apple.*`**. Built by **`record_nonbrew_applications`** in **`modules/nonbrew-apps.sh`**; **`restore.sh`** calls **`show_nonbrew_applications`** after SOPS. Heuristic only.

Secrets and paths currently in **`SOPS`** include things like **`.ssh`**, **`.netrc`**, **kube/docker** config, **`.claude.json`**, **`.cursor/mcp.json`**, **ACME** dirs under **`.acme.sh`**, **`.secrets`**, **`.zsh_history`**, etc. Adjust the arrays in **`init.sh`** to match what you want.

## Secrets: age + 1Password

- **Encrypt (backup):** `backup.sh` uses **`--age`** with either **`SOPS_AGE_RECIPIENT`** in **`init.sh`** (your `age1…` public key) or, if that is empty, **`op read "$SOPS_AGE_KEY_RECIPIENT_PATH"`**.
- **Decrypt (restore):** **`modules/sops.sh`** reads the age secret key with **`op read "$SOPS_AGE_KEY_PASSWORD_PATH"`** and sets **`SOPS_AGE_KEY`** for `sops -d`.

The 1Password item fields are documented next to **`SOPS_AGE_KEY_*_PATH`** in **`init.sh`**.

You need the **[1Password CLI](https://developer.1password.com/docs/cli/)** (`op`) signed in for backup encrypt and restore decrypt.

## Running scripts (repo root)

**`backup.sh`** and **`restore.sh`** require **`PWD`** to be the repository root (they `source init.sh`, which checks this).

```sh
cd /path/to/macos-personal
./backup.sh    # refresh backup/ and sops/
./restore.sh   # install tooling and restore home + decrypt sops
```

Or use **`make`** from anywhere:

```sh
make -C /path/to/macos-personal backup
make -C /path/to/macos-personal restore
make -C /path/to/macos-personal brew-cleanup   # optional; see below
```

Running **`make`** with no target runs **`help`** and prints available targets (it does not run backup).

### Prune Homebrew to match the Brewfile

**`make brew-cleanup`** runs **`brew bundle cleanup --force`** against **`backup/Brewfile`**, uninstalling formulae and casks that are **not** listed there. Anything you still use must appear in that file or it will be removed. Run **`brew bundle check --file=backup/Brewfile`** first if you want to see drift without uninstalling.

## New machine checklist

1. Install **Xcode Command Line Tools** — open Terminal and run:
   ```sh
   xcode-select --install
   ```
   Follow the prompt to download and install. This provides **`git`**, **`make`**, compilers, and other prerequisites that Homebrew and the restore scripts depend on.
2. Clone this repo (private) and `cd` into it.
3. Sign in to **1Password** and run **`op signin`** (or use app integration) so **`op read`** works for restore.
4. Run **`./restore.sh`** or **`make restore`** from the repo root.
5. Complete any GUI installer steps (e.g. **Docker Desktop**, **1Password**).
6. **Restart the terminal** (restore prints this as well).

Order of operations in **`restore.sh`**: **oh-my-zsh** (and Powerlevel10k) → **dotfiles / `.config`** → **Homebrew + Brewfile** → **macOS defaults** → **devbox** → **SOPS decrypt**.

## What restore changes on macOS

- **Dock:** autohide, Recents off  
- **Finder:** extensions visible, hidden files, path bar, list view, folders on top, search scoped to current folder  
- **Spaces / Mission Control:** group windows by app  

## Update the backup on your current Mac

From the repo root, with **`op`** authenticated and **Homebrew** available (for `brew bundle dump`):

```sh
./backup.sh
# or: make backup
```

To change what is included, edit **`init.sh`** (`DOTFILES`, `SOPS`) and **`backup.sh`** (`CONFIG_RSYNC_EXCLUDES`). You can also edit **`backup/Brewfile`** by hand or trim it after `brew bundle dump`.

## Credit

- [Jaycedam](https://github.com/Jaycedam/mac-setup)
- [macOS defaults list](https://macos-defaults.com/)
- [Homebrew Bundle](https://docs.brew.sh/Manpage#bundle-subcommand)
