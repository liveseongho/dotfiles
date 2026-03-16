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

# ========== Local config ==========
LOCAL_CONF="$DOTFILES_DIR/local.conf"

load_local_conf() {
  if [ -f "$LOCAL_CONF" ]; then
    source "$LOCAL_CONF"
    ok "Loaded local.conf"
    return 0
  fi
  return 1
}

create_local_conf() {
  header "Local Configuration (first-time setup)"

  info "Creating local.conf for this machine."
  info "This file is gitignored — your settings stay local."
  echo ""

  # Git info
  local current_name current_email
  current_name=$(git config --global user.name 2>/dev/null || echo "")
  current_email=$(git config --global user.email 2>/dev/null || echo "")

  read -rp "  Git user.name [${current_name:-Your Name}]: " git_name
  git_name="${git_name:-$current_name}"
  read -rp "  Git user.email [${current_email:-your@email.com}]: " git_email
  git_email="${git_email:-$current_email}"

  echo ""

  # Symlink mode
  info "How should dotfiles be installed?"
  echo -e "  ${CYAN}link${NC}   — symlink to dotfiles/ (stays synced with repo)"
  echo -e "  ${CYAN}copy${NC}   — copy into ~/ (allows local edits)"
  echo -e "  ${CYAN}append${NC} — append to existing file (bashrc only)"
  echo ""

  local default_mode="link"
  read -rp "  Default mode for all files? [link/copy] (default: link): " chosen_mode
  chosen_mode="${chosen_mode:-$default_mode}"
  case "$chosen_mode" in
    link|copy) ;;
    *) chosen_mode="link" ;;
  esac

  read -rp "  .bashrc mode? [link/copy/append] (default: append): " bashrc_mode
  bashrc_mode="${bashrc_mode:-append}"

  cat > "$LOCAL_CONF" <<EOF
# local.conf — Machine-specific dotfiles configuration
# Generated: $(date +%Y-%m-%d)
# This file is gitignored.

# ========== Git ==========
GIT_USER_NAME="$git_name"
GIT_USER_EMAIL="$git_email"

# ========== Symlink mode ==========
# link = symlink to dotfiles/ (stays synced)
# copy = copy into ~/ (allows local edits)
# append = append to existing (bashrc only)
ZSHRC_MODE="$chosen_mode"
BASHRC_MODE="$bashrc_mode"
VIMRC_MODE="$chosen_mode"
TMUX_MODE="$chosen_mode"
P10K_MODE="$chosen_mode"
GITCONFIG_MODE="copy"
EOF

  echo ""
  ok "local.conf created"
  source "$LOCAL_CONF"
}

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

  # Git config: skip — user sets their own name/email per machine
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
    if [ "$OS" = "Darwin" ] && command -v brew &>/dev/null; then
      brew install fzf
    else
      # No sudo needed — installs to ~/.fzf
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
      ~/.fzf/install --all --no-bash --no-fish --no-update-rc
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

  # Install a dotfile by mode: link, copy, or append
  install_dotfile() {
    local src="$1" dst="$2" mode="$3"

    # Already correct symlink?
    if [ "$mode" = "link" ] && [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      ok "$(basename "$dst") (linked)"
      return
    fi

    # Already identical copy?
    if [ "$mode" = "copy" ] && [ -f "$dst" ] && ! [ -L "$dst" ] && diff -q "$src" "$dst" &>/dev/null; then
      ok "$(basename "$dst") (copy, up to date)"
      return
    fi

    # Existing file — backup first
    if [ -f "$dst" ] || [ -L "$dst" ]; then
      local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      warn "Backed up $(basename "$dst") → $(basename "$backup")"
    fi

    case "$mode" in
      link)
        ln -sf "$src" "$dst"
        ok "$(basename "$dst") (linked)"
        ;;
      copy)
        cp -f "$src" "$dst"
        ok "$(basename "$dst") (copied)"
        ;;
      *)
        err "Unknown mode '$mode' for $(basename "$dst")"
        ;;
    esac
  }

  install_dotfile "$DOTFILES_DIR/zshrc"     "$HOME/.zshrc"     "${ZSHRC_MODE:-link}"
  install_dotfile "$DOTFILES_DIR/vimrc"     "$HOME/.vimrc"     "${VIMRC_MODE:-link}"
  install_dotfile "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf" "${TMUX_MODE:-link}"
  install_dotfile "$DOTFILES_DIR/p10k.zsh"  "$HOME/.p10k.zsh"  "${P10K_MODE:-link}"

  # bashrc: special handling for "append" mode
  local bashrc_mode="${BASHRC_MODE:-append}"
  if [ "$bashrc_mode" = "append" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      if ! grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
        local backup="$HOME/.bashrc.backup.$(date +%Y%m%d%H%M%S)"
        cp "$HOME/.bashrc" "$backup"
        warn "Backed up .bashrc → $(basename "$backup")"
        echo "" >> "$HOME/.bashrc"
        cat "$DOTFILES_DIR/bashrc" >> "$HOME/.bashrc"
        ok ".bashrc (appended zsh switch)"
      else
        ok ".bashrc (already has zsh switch)"
      fi
    else
      install_dotfile "$DOTFILES_DIR/bashrc" "$HOME/.bashrc" "link"
    fi
  else
    install_dotfile "$DOTFILES_DIR/bashrc" "$HOME/.bashrc" "$bashrc_mode"
  fi
}

# ========== Module: gitconfig ==========
install_gitconfig() {
  header "Git Config"

  local dst="$HOME/.gitconfig"
  local src="$DOTFILES_DIR/gitconfig"
  local git_name="${GIT_USER_NAME:-}"
  local git_email="${GIT_USER_EMAIL:-}"

  if [ ! -f "$src" ]; then
    warn "No gitconfig template in dotfiles, skipping"
    return
  fi

  if [ -z "$git_name" ] || [ -z "$git_email" ]; then
    warn "GIT_USER_NAME or GIT_USER_EMAIL not set in local.conf, skipping"
    return
  fi

  # Check if already up to date
  if [ -f "$dst" ] && ! [ -L "$dst" ]; then
    local expected
    expected=$(sed -e "s/name = .*/name = $git_name/" -e "s/email = .*/email = $git_email/" "$src")
    if [ "$(cat "$dst")" = "$expected" ]; then
      ok ".gitconfig (up to date)"
      return
    fi
  fi

  # Backup existing
  if [ -f "$dst" ] || [ -L "$dst" ]; then
    local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    warn "Backed up .gitconfig → $(basename "$backup")"
  fi

  # Generate from template
  sed -e "s/name = .*/name = $git_name/" \
      -e "s/email = .*/email = $git_email/" \
      "$src" > "$dst"

  ok ".gitconfig (name=$git_name, email=$git_email)"
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

    "Symlink .p10k.zsh:test -L $HOME/.p10k.zsh"
    "Git config:test -f $HOME/.gitconfig"
    "local.conf:test -f $DOTFILES_DIR/local.conf"
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
ALL_MODULES="deps omz plugins p10k fonts vim symlinks gitconfig macos"

run_all() {
  setup_repo
  load_local_conf || create_local_conf
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

# ========== Uninstall ==========
run_delete() {
  header "Uninstall Dotfiles"

  echo -e "  ${RED}This will remove all dotfiles symlinks/copies and restore backups.${NC}"
  echo ""
  read -rp "  Are you sure? [y/N] " answer
  case "${answer}" in
    [Yy]*) ;;
    *)
      info "Cancelled."
      return
      ;;
  esac

  local BACKUP_DIR="$HOME/.dotfiles-backup.$(date +%Y%m%d%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  info "Backup directory: $BACKUP_DIR"

  # Remove dotfile if it's ours (symlink to dotfiles/ or installed by us)
  remove_dotfile() {
    local dst="$1" name
    name="$(basename "$dst")"

    if [ ! -f "$dst" ] && [ ! -L "$dst" ]; then
      info "$name — not present, skipping"
      return
    fi

    # Move current file to backup dir
    mv "$dst" "$BACKUP_DIR/$name"
    ok "Removed $name → backed up to $BACKUP_DIR/$name"

    # Restore most recent .backup file if one exists
    local latest_backup
    latest_backup=$(ls -t "${dst}.backup."* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
      mv "$latest_backup" "$dst"
      ok "Restored $name from $(basename "$latest_backup")"
    fi
  }

  remove_dotfile "$HOME/.zshrc"
  remove_dotfile "$HOME/.vimrc"
  remove_dotfile "$HOME/.tmux.conf"
  remove_dotfile "$HOME/.p10k.zsh"
  remove_dotfile "$HOME/.gitconfig"

  # bashrc: if it has our zsh switch, remove those lines
  if [ -f "$HOME/.bashrc" ]; then
    if grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
      cp "$HOME/.bashrc" "$BACKUP_DIR/.bashrc"
      # Remove the appended block (from our bashrc marker to end, or just the exec zsh lines)
      sed -i.bak '/# Auto-switch to zsh/,/exec zsh/d' "$HOME/.bashrc" 2>/dev/null || \
        sed -i '' '/# Auto-switch to zsh/,/exec zsh/d' "$HOME/.bashrc" 2>/dev/null
      # If that didn't work (no marker), just remove exec zsh line
      if grep -q "exec zsh" "$HOME/.bashrc" 2>/dev/null; then
        sed -i.bak '/exec zsh/d' "$HOME/.bashrc" 2>/dev/null || \
          sed -i '' '/exec zsh/d' "$HOME/.bashrc" 2>/dev/null
      fi
      rm -f "$HOME/.bashrc.bak"
      ok "Removed zsh switch from .bashrc (backed up to $BACKUP_DIR/.bashrc)"
    fi
  fi

  # Remove vim colorschemes/autoload we installed
  if [ -d "$HOME/.vim/colors" ]; then
    if [ -d "$DOTFILES_DIR/vim/colors" ]; then
      for f in "$DOTFILES_DIR/vim/colors/"*.vim; do
        local name="$(basename "$f")"
        if [ -f "$HOME/.vim/colors/$name" ]; then
          mv "$HOME/.vim/colors/$name" "$BACKUP_DIR/$name"
          ok "Removed vim color: $name"
        fi
      done
    fi
  fi

  # Remove local.conf
  if [ -f "$LOCAL_CONF" ]; then
    mv "$LOCAL_CONF" "$BACKUP_DIR/local.conf"
    ok "Removed local.conf"
  fi

  # Clean up old .backup files
  echo ""
  local backup_count
  backup_count=$(ls "$HOME"/.*.backup.* 2>/dev/null | wc -l | tr -d ' ')
  if [ "$backup_count" -gt 0 ]; then
    read -rp "  Also clean up $backup_count old .backup files in \$HOME? [y/N] " clean_answer
    case "${clean_answer}" in
      [Yy]*)
        mv "$HOME"/.*.backup.* "$BACKUP_DIR/" 2>/dev/null
        ok "Moved old backups to $BACKUP_DIR/"
        ;;
      *)
        info "Keeping old backup files"
        ;;
    esac
  fi

  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN} ✅ Dotfiles uninstalled${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "  All removed files backed up to: $BACKUP_DIR"
  echo "  The dotfiles repo itself ($DOTFILES_DIR) was NOT deleted."
  echo "  To fully remove: rm -rf $DOTFILES_DIR"
  echo ""
  echo "  Restart your terminal for changes to take effect."
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
    load_local_conf || create_local_conf
    for mod in $ALL_MODULES; do
      install_$mod
    done
    run_font_check
    run_status
    ;;
  "status")
    run_status
    ;;
  "delete"|"uninstall"|"remove")
    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
    LOCAL_CONF="$DOTFILES_DIR/local.conf"
    run_delete
    ;;
  "help"|"--help"|"-h")
    echo "Usage: ./install.sh [command]"
    echo ""
    echo "Commands:"
    echo "  install    Full install (default)"
    echo "  update     Re-check and install missing parts"
    echo "  status     Show installation status"
    echo "  delete     Uninstall dotfiles (backup + restore originals)"
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
      load_local_conf || create_local_conf
      install_$1
    else
      err "Unknown command: $1"
      echo "Run './install.sh help' for usage"
      exit 1
    fi
    ;;
esac
