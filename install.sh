#!/usr/bin/env bash
# Seongho's dotfiles installer
# One-command install:
#   curl -fsSL https://raw.githubusercontent.com/liveseongho/dotfiles/main/install.sh | bash
#
# After install, use:
#   dotfiles              # Full install (all modules)
#   dotfiles update       # Re-check and install missing parts
#   dotfiles status       # Show installation status
#   dotfiles uninstall    # Remove dotfiles (backup + restore originals)
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
  cat > "$LOCAL_CONF" <<EOF
# local.conf — Machine-specific dotfiles configuration
# Generated: $(date +%Y-%m-%d)
# This file is gitignored.

# ========== Git ==========
GIT_USER_NAME="$git_name"
GIT_USER_EMAIL="$git_email"
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
    # Ensure brew is in PATH (curl|bash doesn't load shell profile)
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"

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
      info "Installing $name → $dest"
      git clone "$url" "$dest"
    else
      ok "$name ($dest)"
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
    info "Installing Powerlevel10k → $P10K_DIR"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  else
    ok "Powerlevel10k ($P10K_DIR)"
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
    ok "MesloLGS NF fonts → $FONT_DIR"
  else
    ok "MesloLGS NF fonts ($FONT_DIR)"
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
  ok "Vim colorscheme: ${scheme:-default} ($HOME/.vim/colors/)"
}

# ========== Module: symlinks ==========
install_symlinks() {
  header "Symlinks"

  link_dotfile() {
    local src="$1"
    local dst="$2"
    local local_file="${dst}.local"

    # Already correct symlink
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      ok "$dst → $src"
      return
    fi

    # Existing non-symlink file — backup and migrate to .local
    if [ -f "$dst" ] && ! [ -L "$dst" ]; then
      local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
      cp "$dst" "$backup"
      warn "Backed up $dst → $backup"

      # If .local doesn't exist yet, move existing content there
      if [ ! -f "$local_file" ]; then
        mv "$dst" "$local_file"
        ok "Migrated $(basename "$dst") → $(basename "$local_file") (your custom config preserved)"
      else
        rm "$dst"
      fi
    elif [ -L "$dst" ]; then
      # Wrong symlink target — remove
      rm "$dst"
    fi

    ln -sf "$src" "$dst"
    ok "$dst → $src"

  }

  link_dotfile "$DOTFILES_DIR/zshrc"     "$HOME/.zshrc"
  link_dotfile "$DOTFILES_DIR/bashrc"    "$HOME/.bashrc"
  link_dotfile "$DOTFILES_DIR/vimrc"     "$HOME/.vimrc"
  link_dotfile "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
  link_dotfile "$DOTFILES_DIR/p10k.zsh"  "$HOME/.p10k.zsh"

  # Summary of .local files
  header "Local Overrides"
  for lf in "$HOME/.zshrc.local" "$HOME/.bashrc.local" "$HOME/.vimrc.local" "$HOME/.tmux.conf.local"; do
    local name="$(basename "$lf")"
    if [ -f "$lf" ]; then
      local lines=$(wc -l < "$lf" | tr -d ' ')
      ok "$name ($lines lines)"
    else
      warn "$name (0 lines)"
    fi
  done
}

# ========== Module: gitconfig ==========
install_gitconfig() {
  header "Git Config"

  local dst="$HOME/.gitconfig"

  # Desired settings to ensure (section key value)
  local settings=(
    "credential:helper:store"
    "pull:rebase:true"
  )

  local changed=0

  for entry in "${settings[@]}"; do
    local section="${entry%%:*}"
    local rest="${entry#*:}"
    local key="${rest%%:*}"
    local value="${rest#*:}"

    local current
    current=$(git config --global --get "$section.$key" 2>/dev/null || echo "")

    if [ "$current" = "$value" ]; then
      ok "$section.$key = $value"
    else
      git config --global "$section.$key" "$value"
      ok "$section.$key = $value (set)"
      changed=$((changed + 1))
    fi
  done

  # Set user.name/email from local.conf if not already configured
  local git_name="${GIT_USER_NAME:-}"
  local git_email="${GIT_USER_EMAIL:-}"

  if [ -n "$git_name" ]; then
    local current_name
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    if [ -z "$current_name" ]; then
      git config --global user.name "$git_name"
      ok "user.name = $git_name (set)"
      changed=$((changed + 1))
    else
      ok "user.name = $current_name"
    fi
  fi

  if [ -n "$git_email" ]; then
    local current_email
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    if [ -z "$current_email" ]; then
      git config --global user.email "$git_email"
      ok "user.email = $git_email (set)"
      changed=$((changed + 1))
    else
      ok "user.email = $current_email"
    fi
  fi

  if [ "$changed" -eq 0 ]; then
    ok ".gitconfig (already up to date)"
  fi
}

# ========== Module: macos ==========
install_macos() {
  if [ "$OS" != "Darwin" ]; then
    return
  fi

  header "macOS Preferences"

  defaults write NSGlobalDomain KeyRepeat -int 3
  defaults write NSGlobalDomain InitialKeyRepeat -int 20
  defaults write com.apple.finder AppleShowAllFiles -bool true
  ok "Key repeat, hidden files"
}

# ========== Font check ==========
run_font_check() {
  header "Font Check"

  local py=$(detect_python)

  local py=$(detect_python)
  if [ -n "$py" ] && check_python_version "$py"; then
    $py -c "
symbols = [
    ('Powerline',  '\ue0b0 \ue0b2 \ue0b1 \ue0b3'),
    ('Nerd Font',  '\uf296 \uf120 \uf1d3 \uf09b \ue711 \uf0e7'),
    ('Git icons',  '\ue725 \ue728 \uf418 \uf417'),
    ('Arrows',     '\uf061 \uf060 \uf062 \uf063'),
    ('Box',        '\u256d\u2500\u256e\u2502 \u2502\u2570\u2500\u256f'),
]
for label, chars in symbols:
    print(f'\033[0;32m[ok]\033[0m {label:14s} {chars}')
"
    info "Broken symbols? Set terminal font to MesloLGS NF — https://github.com/liveseongho/dotfiles#fonts"
  else
    warn "Python >= $MIN_PYTHON_VERSION not found — run 'p10k configure' to verify fonts"
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
    ".zshrc:test -L $HOME/.zshrc"
    ".bashrc:test -L $HOME/.bashrc"
    ".vimrc:test -L $HOME/.vimrc"
    ".tmux.conf:test -L $HOME/.tmux.conf"
    ".p10k.zsh:test -L $HOME/.p10k.zsh"
    ".gitconfig:test -f $HOME/.gitconfig"
    "local.conf:test -f $DOTFILES_DIR/local.conf"
  )

  local missing=0
  local missing_names=()
  local total=${#checks[@]}

  for check in "${checks[@]}"; do
    local name="${check%%:*}"
    local cmd="${check#*:}"
    if ! eval "$cmd" &>/dev/null; then
      missing=$((missing + 1))
      missing_names+=("$name")
    fi
  done

  local py=$(detect_python)
  local pyver=""
  if [ -n "$py" ]; then
    pyver=$($py -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')")
  fi

  echo ""
  if [ "$missing" -eq 0 ]; then
    ok "All $total checks passed${pyver:+ · Python $pyver}"
  else
    ok "$((total - missing))/$total passed${pyver:+ · Python $pyver}"
    for name in "${missing_names[@]}"; do
      warn "$name — not installed"
    done
    echo ""
    info "Run 'dotfiles update' to fix."
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
  echo -e "${GREEN}  Dotfiles installed successfully!${NC}"
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

  # Remove dotfile and optionally restore from backup
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

    # Check for previous backups
    local backups
    backups=($(ls -t "${dst}.backup."* 2>/dev/null))

    if [ ${#backups[@]} -gt 0 ]; then
      echo ""
      info "Found ${#backups[@]} backup(s) for $name:"
      local i=1
      for b in "${backups[@]}"; do
        local ts=$(echo "$b" | grep -oE '[0-9]{14}$')
        local pretty=""
        if [ -n "$ts" ]; then
          pretty="${ts:0:4}-${ts:4:2}-${ts:6:2} ${ts:8:2}:${ts:10:2}:${ts:12:2}"
        fi
        echo -e "  ${CYAN}[$i]${NC} $(basename "$b")${pretty:+  ($pretty)}"
        i=$((i + 1))
      done
      echo -e "  ${CYAN}[0]${NC} Don't restore"
      echo ""
      read -rp "  Restore which backup? [0-$((${#backups[@]}))] (default: 0): " choice
      choice="${choice:-0}"

      if [ "$choice" -gt 0 ] 2>/dev/null && [ "$choice" -le "${#backups[@]}" ]; then
        local selected="${backups[$((choice - 1))]}"
        mv "$selected" "$dst"
        ok "Restored $name from $(basename "$selected")"
      else
        info "Not restoring $name"
      fi
    fi
  }

  for dst in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.vimrc" "$HOME/.tmux.conf" "$HOME/.p10k.zsh"; do
    remove_dotfile "$dst"
  done

  # Note: .local files are intentionally preserved
  local local_files=()
  for lf in "$HOME/.zshrc.local" "$HOME/.bashrc.local" "$HOME/.vimrc.local" "$HOME/.tmux.conf.local"; do
    [ -f "$lf" ] && local_files+=("$(basename "$lf")")
  done
  if [ ${#local_files[@]} -gt 0 ]; then
    info "Kept local config files: ${local_files[*]}"
  fi

  # gitconfig: only remove settings we added (keep user.name/email)
  header "Git Config Cleanup"
  local gc_settings=("credential.helper" "pull.rebase")
  for key in "${gc_settings[@]}"; do
    if git config --global --get "$key" &>/dev/null; then
      git config --global --unset "$key"
      ok "Removed $key"
    fi
  done

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
  echo -e "${GREEN}  Dotfiles uninstalled${NC}"
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
  "uninstall"|"delete"|"remove")
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
    echo "  uninstall  Remove dotfiles (backup + restore originals)"
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
