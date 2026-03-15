# ~/.zshrc
# Seongho's dotfiles — https://github.com/liveseongho/dotfiles

# ========== Oh My Zsh ==========
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# ========== History ==========
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_ignore_space
setopt share_history
setopt inc_append_history

# ========== PATH ==========
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# ========== Aliases ==========
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# ========== Powerlevel10k ==========
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
