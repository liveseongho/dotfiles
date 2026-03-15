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
| `macos` | macOS preferences (key repeat, hidden files) |

## What's included

```
~/dotfiles/
├── install.sh        # Modular installer
├── bin/dotfiles      # CLI wrapper (dotfiles update/status/...)
├── zshrc             # → ~/.zshrc
├── bashrc            # → appended to ~/.bashrc (auto zsh switch)
├── vimrc             # → ~/.vimrc
├── tmux.conf         # → ~/.tmux.conf
├── gitconfig         # → ~/.gitconfig
├── p10k.zsh          # → ~/.p10k.zsh
└── vim/
    ├── colors/
    │   ├── one-monokai.vim
    │   └── onedark.vim
    └── autoload/
        └── onedark.vim
```

## Features

- **zsh** — Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting
- **fzf** — Ctrl+R history search, Ctrl+T file search, Alt+C directory jump
- **vim** — One Monokai colorscheme, sensible defaults
- **tmux** — Mouse support, 256 colors
- **git** — Useful aliases, rebase pull, auto remote setup
- **bashrc** — Auto-switch to zsh (appends, never overwrites)
- **HPC** — Environment Modules support for Linux servers
- **Fonts** — MesloLGS NF auto-downloaded + symbol check

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
rm ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig ~/.p10k.zsh
rm -rf ~/.vim/colors/onedark.vim ~/.vim/colors/one-monokai.vim ~/.vim/autoload/onedark.vim
rm -rf ~/dotfiles
# Restore backups if needed
ls ~/.*backup* 2>/dev/null
```
