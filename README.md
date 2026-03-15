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
| `plugins` | zsh-autosuggestions, zsh-syntax-highlighting |
| `p10k` | Powerlevel10k theme |
| `fonts` | MesloLGS NF fonts (auto-downloaded) |
| `vim` | Vim config + One Dark colorscheme |
| `symlinks` | Symlink all config files to `~/dotfiles/` |
| `macos` | macOS preferences (key repeat, hidden files) |

## What's included

```
~/dotfiles/
├── install.sh      # Modular installer
├── zshrc           # → ~/.zshrc
├── vimrc           # → ~/.vimrc
├── tmux.conf       # → ~/.tmux.conf
├── gitconfig       # → ~/.gitconfig
├── p10k.zsh        # → ~/.p10k.zsh
└── vim/
    ├── colors/onedark.vim
    └── autoload/onedark.vim
```

## Requirements

| Requirement | Status |
|-------------|--------|
| macOS / Linux | ✅ Both supported |
| git, curl, zsh | Auto-installed on Linux (apt, yum, pacman, apk) |
| Python >= 3.7 | Optional (for font symbol check) |
| Homebrew | Auto-installed on macOS |

### Python compatibility

The font symbol check requires Python >= 3.7. Both `python3` and `python` binaries are detected automatically. If Python is not available, the font check is skipped and all other modules install normally.

## Supported platforms

- **macOS** (Apple Silicon & Intel)
- **Linux** — Ubuntu/Debian (apt), CentOS/RHEL (yum), Arch (pacman), Alpine (apk)

## After install

```bash
p10k configure    # Set up your prompt style (optional, config included)
```

## Uninstall

```bash
rm ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig ~/.p10k.zsh
rm -rf ~/.vim/colors/onedark.vim ~/.vim/autoload/onedark.vim
# Restore backups if needed
ls ~/.*backup* 2>/dev/null
```
