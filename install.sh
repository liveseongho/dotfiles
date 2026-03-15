#!/usr/bin/env bash
# Seongho's dotfiles installer
# One-command install:
#   curl -fsSL https://raw.githubusercontent.com/liveseongho/dotfiles/main/install.sh | bash
#
# After install, use:
#   dotfiles              # Full install (all modules)
#   dotfiles update       # Re-check and install missing parts
#   dotfiles status       # Show installation status
#   dotfiles <module>     # Install specific module only
#
# Modules: deps, omz, plugins, p10k, fonts, vim, symlinks, macos

set -e

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
REPO="https://github.com/liveseongho/dotfiles.git"
OS="$(uname -s)"
MIN_PYTHON_VERSION="3.7"

# ========== Colors ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC} $1"; }
ok()    { echo -e "${GREEN}[ok]${NC} $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }
header() { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}"; }

# ========== Python detection ==========
detect_python() {
  if command -v python3 &>/dev/null; then
    echo "python3"
  elif command -v python &>/dev/null && python -c "import sys; assert sys.version_info[0]>=3" 2>/dev/null; then
    echo "python"
  else
    echo ""
  fi
}

check_python_version() {
  local py="$1"
  if [ -z "$py" ]; then
    return 1
  fi
  $py -c "import sys; v=sys.version_info; exit(0 if (v[0],v[1]) >= (3,7) else 1)" 2>/dev/null
}

# ========== Clone if running via curl ==========
setup_repo() {
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
}

# ========== Module: deps ==========
install_deps() {
  header "Dependencies"

  if [ "$OS" = "Darwin" ]; then
    if ! command -v brew &>/dev/null; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      ok "Homebrew"
    fi
  elif [ "$OS" = "Linux" ]; then
    local missing=""
    for cmd in zsh git curl; do
      command -v "$cmd" &>/dev/null || missing="$missing $cmd"
    done

    local py=$(detect_python)
    if [ -z "$py" ]; then
      missing="$missing python3"
    fi

    if [ -n "$missing" ]; then
      info "Installing:$missing"
      if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq $missing
      elif command -v yum &>/dev/null; then
        sudo yum install -y $missing
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm $missing
      elif command -v apk &>/dev/null; then
        apk add --no-cache $missing
      else
        err "Unknown package manager. Please install manually:$missing"
        return 1
      fi
    else
      ok "All dependencies installed"
    fi
  fi

  # Python version check
  local py=$(detect_python)
  if [ -n "$py" ]; then
    local pyver=$($py -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')")
    if check_python_version "$py"; then
      ok "Python $pyver ($py) >= $MIN_PYTHON_VERSION"
    else
      warn "Python $pyver found but >= $MIN_PYTHON_VERSION required"
    fi
  else
    warn "Python not found (optional, needed for font check)"
  fi

  # Git config
  if [ -z "$(git config --global user.name)" ]; then
    info "Setting git config..."
    git config --global user.name "liveseongho"
    git config --global user.email "liveseongho@gmail.com"
  fi
}

# ========== Module: omz ==========
install_omz() {
  header "Oh My Zsh"

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    ok "Oh My Zsh"
  fi
}

# ========== Module: plugins ==========
install_plugins() {
  header "Zsh Plugins"

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  clone_plugin() {
    local name="$1" url="$2"
    local dest="$ZSH_CUSTOM/plugins/$name"
    if [ ! -d "$dest" ]; then
      info "Installing $name..."
      git clone "$url" "$dest"
    else
      ok "$name"
    fi
  }

  clone_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
  clone_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
  # fzf
  if ! command -v fzf &>/dev/null; then
    info "Installing fzf..."
    if [ "$OS" = "Darwin" ]; then
      brew install fzf
    elif command -v apt-get &>/dev/null; then
      sudo apt-get install -y -qq fzf
    elif command -v yum &>/dev/null; then
      sudo yum install -y fzf
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm fzf
    else
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all --no-bash --no-fish
    fi
  else
    ok "fzf"
  fi
}

# ========== Module: p10k ==========
install_p10k() {
  header "Powerlevel10k"

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

  if [ ! -d "$P10K_DIR" ]; then
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  else
    ok "Powerlevel10k"
  fi
}

# ========== Module: fonts ==========
install_fonts() {
  header "Fonts (MesloLGS NF)"

  if [ "$OS" = "Darwin" ]; then
    local FONT_DIR="$HOME/Library/Fonts"
  elif [ "$OS" = "Linux" ]; then
    local FONT_DIR="$HOME/.local/share/fonts"
  else
    warn "Unsupported OS for font install"
    return
  fi

  if [ ! -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
    info "Downloading MesloLGS NF fonts..."
    mkdir -p "$FONT_DIR"
    for style in "Regular" "Bold" "Italic" "Bold%20Italic"; do
      curl -fsSL "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${style}.ttf" \
        -o "$FONT_DIR/MesloLGS NF ${style//%20/ }.ttf"
    done
    if [ "$OS" = "Linux" ] && command -v fc-cache &>/dev/null; then
      fc-cache -f "$FONT_DIR"
    fi
    ok "MesloLGS NF fonts installed"
  else
    ok "MesloLGS NF fonts"
  fi
}

# ========== Module: vim ==========
install_vim() {
  header "Vim"

  mkdir -p "$HOME/.vim/colors" "$HOME/.vim/autoload"

  # Copy all colorschemes and autoload files from dotfiles
  if [ -d "$DOTFILES_DIR/vim/colors" ]; then
    cp -f "$DOTFILES_DIR/vim/colors/"*.vim "$HOME/.vim/colors/" 2>/dev/null
  fi
  if [ -d "$DOTFILES_DIR/vim/autoload" ]; then
    cp -f "$DOTFILES_DIR/vim/autoload/"*.vim "$HOME/.vim/autoload/" 2>/dev/null
  fi

  # Show active colorscheme from vimrc
  local scheme=$(grep "^colorscheme" "$DOTFILES_DIR/vimrc" 2>/dev/null | awk '{print $2}')
  ok "Vim colorscheme: ${scheme:-default}"
}

# ========== Module: symlinks ==========
install_symlinks() {
  header "Symlinks"

  link_file() {
    local src="$1" dst="$2"
    if [ -f "$dst" ] || [ -L "$dst" ]; then
      if [ "$(readlink "$dst")" = "$src" ]; then
        ok "$(basename "$dst")"
        return
      fi
      warn "Backing up $(basename "$dst")"
      mv "$dst" "${dst}.backup.$(date +%Y%m%d%H%M%S)"
    fi
    ln -sf "$src" "$dst"
    ok "Linked $(basename "$dst")"
  }

  link_file "$DOTFILES_DIR/zshrc"     "$HOME/.zshrc"
  # bashrc: append zsh auto-switch instead of overwriting
  if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
      info "Appending zsh auto-switch to existing .bashrc"
      echo "" >> "$HOME/.bashrc"
      cat "$DOTFILES_DIR/bashrc" >> "$HOME/.bashrc"
      ok "Appended to .bashrc"
    else
      ok ".bashrc already has zsh switch"
    fi
  else
    link_file "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
  fi
  link_file "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
  link_file "$DOTFILES_DIR/vimrc"     "$HOME/.vimrc"
  link_file "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/p10k.zsh"  "$HOME/.p10k.zsh"
}

# ========== Module: macos ==========
install_macos() {
  if [ "$OS" != "Darwin" ]; then
    return
  fi

  header "macOS Preferences"

  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write com.apple.finder AppleShowAllFiles -bool true
  ok "Key repeat, hidden files"
}

# ========== Font check ==========
run_font_check() {
  header "Font Check"

  local py=$(detect_python)

  if [ -n "$py" ] && check_python_version "$py"; then
    echo ""
    echo "  Check that all symbols below render correctly:"
    echo ""
    $py -c "
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
    echo ""
    echo -e "  ${GREEN}All symbols visible? You're good to go!${NC}"
    echo -e "  ${YELLOW}Broken symbols? Change your terminal font to 'MesloLGS NF'${NC}"
    echo ""
    echo "  iTerm2:    Preferences > Profiles > Text > Font > MesloLGS NF"
    echo "  Terminal:  Preferences > Profiles > Font > Change > MesloLGS NF"
    echo "  VS Code:   Settings > Terminal Font > 'MesloLGS NF'"
  else
    warn "Python >= $MIN_PYTHON_VERSION not found, skipping symbol check"
    echo "  Run 'p10k configure' to verify your font setup"
  fi
}

# ========== Status ==========
run_status() {
  header "Status"

  local checks=(
    "zsh:command -v zsh"
    "git:command -v git"
    "curl:command -v curl"
    "Oh My Zsh:test -d $HOME/.oh-my-zsh"
    "zsh-autosuggestions:test -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    "zsh-syntax-highlighting:test -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    "fzf:command -v fzf"
    "Powerlevel10k:test -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    "Vim colorscheme:test -f $HOME/.vim/colors/one-monokai.vim -o -f $HOME/.vim/colors/onedark.vim"
    "bashrc zsh switch:grep -q 'exec zsh' $HOME/.bashrc 2>/dev/null"
    "Symlink .zshrc:test -L $HOME/.zshrc"
    "Symlink .vimrc:test -L $HOME/.vimrc"
    "Symlink .tmux.conf:test -L $HOME/.tmux.conf"
    "Symlink .gitconfig:test -L $HOME/.gitconfig"
    "Symlink .p10k.zsh:test -L $HOME/.p10k.zsh"
  )

  local missing=0
  for check in "${checks[@]}"; do
    local name="${check%%:*}"
    local cmd="${check#*:}"
    if eval "$cmd" &>/dev/null; then
      ok "$name"
    else
      warn "$name — not installed"
      missing=$((missing + 1))
    fi
  done

  local py=$(detect_python)
  if [ -n "$py" ]; then
    local pyver=$($py -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')")
    ok "Python $pyver"
  else
    warn "Python — not found (optional)"
  fi

  echo ""
  if [ "$missing" -eq 0 ]; then
    echo -e "  ${GREEN}Everything installed!${NC}"
  else
    echo -e "  ${YELLOW}$missing item(s) missing. Run 'dotfiles update' to fix.${NC}"
  fi
}

# ========== Main ==========
ALL_MODULES="deps omz plugins p10k fonts vim symlinks macos"

run_all() {
  setup_repo
  for mod in $ALL_MODULES; do
    install_$mod
  done
  run_font_check

  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN} ✅ Dotfiles installed successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "  Restart your terminal or run: source ~/.zshrc"
  echo ""
}

case "${1:-}" in
  ""|"install")
    run_all
    ;;
  "update")
    info "Pulling latest from GitHub..."
    cd "$DOTFILES_DIR"
    git stash -q 2>/dev/null
    git pull --rebase origin main
    git stash pop -q 2>/dev/null
    echo ""
    info "Re-running with latest version..."
    exec "$DOTFILES_DIR/install.sh" _update_run
    ;;
  "_update_run")
    # Internal: called after git pull to run with fresh code
    for mod in $ALL_MODULES; do
      install_$mod
    done
    run_font_check
    run_status
    ;;
  "status")
    run_status
    ;;
  "help"|"--help"|"-h")
    echo "Usage: ./install.sh [command]"
    echo ""
    echo "Commands:"
    echo "  install    Full install (default)"
    echo "  update     Re-check and install missing parts"
    echo "  status     Show installation status"
    echo "  help       Show this help"
    echo ""
    echo "Modules: $ALL_MODULES"
    echo "  ./install.sh <module>    Install specific module only"
    echo ""
    echo "Requirements:"
    echo "  - git, curl, zsh (auto-installed on Linux)"
    echo "  - Python >= $MIN_PYTHON_VERSION (optional, for font check)"
    ;;
  *)
    # Single module install
    if echo "$ALL_MODULES" | grep -qw "$1"; then
      setup_repo
      install_$1
    else
      err "Unknown command: $1"
      echo "Run './install.sh help' for usage"
      exit 1
    fi
    ;;
esac
