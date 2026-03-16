# dotfiles

Seongho's terminal & dev environment.

## One-command install

```bash
curl -fsSL https://raw.githubusercontent.com/liveseongho/dotfiles/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/liveseongho/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

## Commands

After install, `dotfiles` is available globally:

```bash
dotfiles              # Full install (all modules)
dotfiles update       # Re-check and install missing parts
dotfiles status       # Show what's installed and what's missing
dotfiles uninstall    # Remove dotfiles (backup + restore originals)
dotfiles <module>     # Install specific module only
dotfiles help         # Show usage
```

## Modules

| Module | Description |
|--------|-------------|
| `deps` | System dependencies (zsh, git, curl, python3, Homebrew on macOS) |
| `omz` | Oh My Zsh |
| `plugins` | zsh-autosuggestions, zsh-syntax-highlighting, fzf |
| `p10k` | Powerlevel10k theme |
| `fonts` | MesloLGS NF fonts (auto-downloaded) |
| `vim` | Vim config + One Monokai colorscheme |
| `symlinks` | Symlink/copy config files (mode per `local.conf`) |
| `gitconfig` | Git config from template + per-machine user info |
| `macos` | macOS preferences (key repeat, hidden files) |

## What's included

```
~/dotfiles/
├── install.sh        # Modular installer
├── bin/dotfiles      # CLI wrapper (dotfiles update/status/...)
├── local.conf.example# Template for per-machine config
├── local.conf        # Your machine config (gitignored)
├── zshrc             # → ~/.zshrc
├── bashrc            # → appended to ~/.bashrc (auto zsh switch)
├── vimrc             # → ~/.vimrc
├── tmux.conf         # → ~/.tmux.conf
├── p10k.zsh          # → ~/.p10k.zsh
├── gitconfig         # → ~/.gitconfig (template, name/email from local.conf)
└── vim/
    ├── colors/
    │   ├── one-monokai.vim
    │   └── onedark.vim
    └── autoload/
        └── onedark.vim
```

## Per-machine configuration (`local.conf`)

On first install, you'll be asked to create `local.conf` with your machine-specific settings. This file is **gitignored** — your settings stay local.

```bash
# local.conf example
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"

ZSHRC_MODE="link"       # link | copy
BASHRC_MODE="append"    # link | copy | append
VIMRC_MODE="link"       # link | copy
TMUX_MODE="link"        # link | copy
P10K_MODE="link"        # link | copy
GITCONFIG_MODE="copy"   # always copy (per-machine user/email)
```

- **link** — symlink to `~/dotfiles/` (stays synced with repo)
- **copy** — copy into `~/` (allows local edits without affecting repo)
- **append** — append to existing file (bashrc only)

## Features

- **zsh** — Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting
- **fzf** — Ctrl+R history search, Ctrl+T file search, Alt+C directory jump
- **vim** — One Monokai colorscheme, sensible defaults, `tabstop=4`
- **tmux** — Prefix `C-a`, mouse support, 256 colors, 50k scrollback
- **git** — `credential.helper=store`, `pull.rebase=true`, per-machine user/email via `local.conf`
- **bashrc** — Auto-switch to zsh (appends, never overwrites)
- **HPC** — Environment Modules support, `squeue`/`sinfo` aliases
- **Fonts** — MesloLGS NF auto-downloaded + symbol check

## Aliases

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `sq` | `squeue` |
| `si` | `sinfo` |
| `ta` | `tmux attach -t` |
| `tn` | `tmux new -s` |

## Requirements

| Requirement | Status |
|-------------|--------|
| macOS / Linux | ✅ Both supported |
| git, curl, zsh | Auto-installed on Linux (apt, yum, pacman, apk) |
| Python >= 3.7 | Optional (for font symbol check) |
| Homebrew | Auto-installed on macOS |
| sudo | Not required (fzf installs to ~/.fzf on Linux) |

## Supported platforms

- **macOS** (Apple Silicon & Intel)
- **Linux** — Ubuntu/Debian (apt), CentOS/RHEL (yum), Arch (pacman), Alpine (apk)
- **HPC servers** — Environment Modules compatible, no sudo required

## After install

```bash
p10k configure    # Set up your prompt style (optional, config included)
```

## Uninstall

```bash
dotfiles uninstall
```

This will:
1. Back up all current dotfiles to `~/.dotfiles-backup.<timestamp>/`
2. Restore the most recent pre-dotfiles backup if available
3. Remove zsh switch from `.bashrc`
4. Clean up vim colorschemes and `local.conf`
5. Optionally clean old `.backup` files

The dotfiles repo itself (`~/dotfiles/`) is **not deleted** — remove manually with `rm -rf ~/dotfiles` if desired.
