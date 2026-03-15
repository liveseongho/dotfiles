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

# ========== Dependencies ==========
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    ok "Homebrew already installed"
  fi
elif [ "$OS" = "Linux" ]; then
  # Install zsh, git, curl if missing
  if ! command -v zsh &>/dev/null || ! command -v git &>/dev/null || ! command -v curl &>/dev/null; then
    info "Installing dependencies (zsh, git, curl)..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y -qq zsh git curl python3
    elif command -v yum &>/dev/null; then
      sudo yum install -y zsh git curl python3
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm zsh git curl python
    elif command -v apk &>/dev/null; then
      apk add --no-cache zsh git curl python3
    else
      err "Could not detect package manager. Please install zsh, git, curl manually."
      exit 1
    fi
  else
    ok "Dependencies already installed"
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

clone_plugin() {
  local name="$1" url="$2"
  local dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    info "Installing $name..."
    git clone "$url" "$dest"
  else
    ok "$name already installed"
  fi
}

clone_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
clone_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

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

# Vim colorscheme
mkdir -p "$HOME/.vim/colors" "$HOME/.vim/autoload"
cp -f "$DOTFILES_DIR/vim/colors/onedark.vim" "$HOME/.vim/colors/" 2>/dev/null
cp -f "$DOTFILES_DIR/vim/autoload/onedark.vim" "$HOME/.vim/autoload/" 2>/dev/null
link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"

# ========== Powerlevel10k config ==========
link_file "$DOTFILES_DIR/p10k.zsh" "$HOME/.p10k.zsh"

# ========== Fonts (MesloLGS NF for Powerlevel10k) ==========
if [ "$OS" = "Darwin" ]; then
  FONT_DIR="$HOME/Library/Fonts"
elif [ "$OS" = "Linux" ]; then
  FONT_DIR="$HOME/.local/share/fonts"
fi

if [ ! -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
  info "Installing MesloLGS NF fonts..."
  mkdir -p "$FONT_DIR"
  for style in "Regular" "Bold" "Italic" "Bold%20Italic"; do
    curl -fsSL "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${style}.ttf" -o "$FONT_DIR/MesloLGS NF ${style//%20/ }.ttf"
  done
  # Refresh font cache on Linux
  if [ "$OS" = "Linux" ] && command -v fc-cache &>/dev/null; then
    fc-cache -f "$FONT_DIR"
  fi
  ok "MesloLGS NF fonts installed"
else
  ok "MesloLGS NF fonts already installed"
fi

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

# ========== Font check ==========
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} 🔤 Font Check (MesloLGS NF)${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "  Check that all symbols below render correctly:"
echo ""
PYTHON=""
if command -v python3 &>/dev/null; then
  PYTHON="python3"
elif command -v python &>/dev/null && python -c "import sys; assert sys.version_info[0]>=3" 2>/dev/null; then
  PYTHON="python"
fi

if [ -n "$PYTHON" ]; then
  $PYTHON -c "
symbols = [
    ('Powerline',  '\ue0b0 \ue0b2 \ue0b1 \ue0b3'),
    ('Nerd Font',  '\uf296 \uf120 \uf1d3 \uf09b \ue711 \uf0e7'),
    ('Git icons',  '\ue725 \ue728 \uf418 \uf417'),
    ('Arrows',     '\uf061 \uf060 \uf062 \uf063'),
    ('Box drawing', '\u256d\u2500\u256e\u2502 \u2502\u2570\u2500\u256f'),
]
for label, chars in symbols:
    print(f'  {label:14s} {chars}')
"
else
  warn "python3 not found, skipping symbol check"
  echo "  Run 'p10k configure' to verify your font setup"
fi
echo ""
echo -e "  ${GREEN}All symbols visible? You're good to go!${NC}"
echo -e "  ${YELLOW}Broken symbols? Change your terminal font to 'MesloLGS NF'${NC}"
echo ""
echo "  iTerm2:    Preferences → Profiles → Text → Font → MesloLGS NF"
echo "  Terminal:  Preferences → Profiles → Font → Change → MesloLGS NF"
echo "  VS Code:   Settings → Terminal Font → 'MesloLGS NF'"
echo ""

# ========== Done ==========
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} ✅ Dotfiles installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Restart your terminal or run: source ~/.zshrc"
echo ""
