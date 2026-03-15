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

## What's included

| File | Description |
|------|-------------|
| `zshrc` | Oh My Zsh + Powerlevel10k + plugins |
| `vimrc` | Clean vim config with sensible defaults |
| `tmux.conf` | Mouse support, 256 colors, zsh shell |
| `gitconfig` | Aliases, rebase pull, auto remote setup |
| `install.sh` | Automated installer (idempotent) |

### Zsh plugins
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — fish-like suggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — command coloring
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) — fast, customizable prompt

### macOS tweaks (auto-applied)
- Faster key repeat
- Show hidden files in Finder

## After install

```bash
p10k configure    # Set up your prompt style
```

## Structure

```
~/dotfiles/
├── README.md
├── install.sh      # One-command installer
├── zshrc           # → ~/.zshrc
├── vimrc           # → ~/.vimrc
├── tmux.conf       # → ~/.tmux.conf
└── gitconfig       # → ~/.gitconfig
```

All config files are symlinked from `~/dotfiles/` — edit once, applied everywhere.
