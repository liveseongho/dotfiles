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
dotfiles update       # Pull latest + re-install
dotfiles status       # Show what's installed
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
| `symlinks` | Symlink all config files to `~/dotfiles/` |
| `gitconfig` | Git settings (`credential.helper`, `pull.rebase`) |
| `macos` | macOS preferences (key repeat, hidden files) |

## What's included

```
~/dotfiles/
├── install.sh         # Modular installer
├── bin/dotfiles       # CLI wrapper
├── local.conf.example # Template for per-machine config
├── zshrc              # → ~/.zshrc
├── bashrc             # → ~/.bashrc (auto-switch to zsh)
├── vimrc              # → ~/.vimrc
├── tmux.conf          # → ~/.tmux.conf
├── p10k.zsh           # → ~/.p10k.zsh
└── vim/
    ├── colors/        # One Monokai, OneDark
    └── autoload/
```

## Per-machine configuration

### `local.conf` — Git user info

On first install, you'll be asked for your git name/email. Stored in `local.conf` (gitignored).

```bash
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"
```

### `.local` files — Machine-specific overrides

All config files are **symlinked** to `~/dotfiles/`. To add machine-specific config (conda init, module load, extra aliases, etc.), create `.local` files:

| Dotfile | Local override |
|---------|---------------|
| `~/.zshrc` | `~/.zshrc.local` |
| `~/.bashrc` | `~/.bashrc.local` |
| `~/.vimrc` | `~/.vimrc.local` |
| `~/.tmux.conf` | `~/.tmux.conf.local` |

`.local` files are automatically sourced and **never touched** by `dotfiles update` or `dotfiles uninstall`.

If an existing rc file is found during install, it's automatically backed up and migrated to the corresponding `.local` file.

## Features

- **zsh** — Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting
- **fzf** — Ctrl+R history search, Ctrl+T file search, Alt+C directory jump
- **vim** — One Monokai colorscheme, sensible defaults, `tabstop=4`
- **tmux** — Prefix `C-a`, mouse support, 256 colors, 50k scrollback
- **git** — `credential.helper=store`, `pull.rebase=true`, per-machine user/email via `local.conf`
- **HPC** — Environment Modules support, `squeue`/`sinfo` aliases
- **Fonts** — MesloLGS NF auto-downloaded + symbol check

## Fonts

MesloLGS NF is auto-installed by the `fonts` module. If symbols look broken, set your terminal font:

| Terminal | Setting |
|----------|---------|
| **iTerm2** | Preferences → Profiles → Text → Font → `MesloLGS NF` |
| **Terminal.app** | Preferences → Profiles → Font → Change → `MesloLGS NF` |
| **VS Code** | Settings → Terminal Font → `MesloLGS NF` |
| **Windows Terminal** | Settings → Profile → Appearance → Font → `MesloLGS NF` |
| **GNOME Terminal** | Preferences → Profile → Custom font → `MesloLGS NF` |

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
| git, curl, zsh | Auto-installed on Linux |
| Python >= 3.7 | Optional (for font symbol check) |
| Homebrew | Auto-installed on macOS |
| sudo | Not required on macOS; optional on Linux |

## Uninstall

```bash
dotfiles uninstall
```

- Backs up all current dotfiles to `~/.dotfiles-backup.<timestamp>/`
- Offers to restore from previous backups per file
- Removes only git settings added by dotfiles (keeps `user.name`/`email`)
- Preserves `.local` files
- Does **not** delete `~/dotfiles/` itself
