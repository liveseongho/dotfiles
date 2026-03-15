#!/usr/bin/env bash
# Seongho's dotfiles installer
# One-command install:
#   curl -fsSL https://raw.githubusercontent.com/liveseongho/dotfiles/main/install.sh | bash
#
# Or clone & run:
#   git clone https://github.com/liveseongho/dotfiles ~/dotfiles && ~/dotfiles/install.sh

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO="https://github.com/liveseongho/dotfiles.git"

# ========== Colors ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC} $1"; }
ok()    { echo -e "${GREEN}[ok]${NC} $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }

# ========== Clone if running via curl ==========
if [ ! -f "$DOTFILES_DIR/install.sh" ]; then
  info "Cloning dotfiles into $DOTFILES_DIR..."
  if [ -d "$DOTFILES_DIR" ]; then
    warn "$DOTFILES_DIR already exists, pulling latest..."
    cd "$DOTFILES_DIR" && git pull
  else
    git clone "$REPO" "$DOTFILES_DIR"
  fi
fi

cd "$DOTFILES_DIR"

# ========== Detect OS ==========
OS="$(uname -s)"
info "Detected OS: $OS"

# ========== Homebrew (macOS) ==========
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    ok "Homebrew already installed"
  fi
fi

# ========== Git config ==========
if [ -z "$(git config --global user.name)" ]; then
  info "Setting git config..."
  git config --global user.name "liveseongho"
  git config --global user.email "liveseongho@gmail.com"
fi

# ========== Oh My Zsh ==========
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  ok "Oh My Zsh already installed"
fi

# ========== Zsh Plugins ==========
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

declare -A plugins=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

for name in "${!plugins[@]}"; do
  dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    info "Installing $name..."
    git clone "${plugins[$name]}" "$dest"
  else
    ok "$name already installed"
  fi
done

# ========== Powerlevel10k ==========
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  info "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  ok "Powerlevel10k already installed"
fi

# ========== Symlinks ==========
info "Creating symlinks..."

link_file() {
  local src="$1" dst="$2"
  if [ -f "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      ok "$(basename "$dst") already linked"
      return
    fi
    warn "Backing up existing $(basename "$dst")"
    mv "$dst" "${dst}.backup.$(date +%Y%m%d%H%M%S)"
  fi
  ln -sf "$src" "$dst"
  ok "Linked $(basename "$dst")"
}

link_file "$DOTFILES_DIR/zshrc"     "$HOME/.zshrc"
link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/vimrc"     "$HOME/.vimrc"
link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"

# ========== macOS defaults ==========
if [ "$OS" = "Darwin" ]; then
  info "Applying macOS preferences..."
  # Faster key repeat
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  # Show hidden files in Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true
  ok "macOS preferences applied"
fi

# ========== Done ==========
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} ✅ Dotfiles installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Restart your terminal or run: source ~/.zshrc"
echo "  Then run: p10k configure"
echo ""
