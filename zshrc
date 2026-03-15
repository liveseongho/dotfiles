# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ~/.zshrc
# Seongho's dotfiles — https://github.com/liveseongho/dotfiles

# ========== Guard: zsh only ==========
if [ -z "$ZSH_VERSION" ]; then
  return 0 2>/dev/null || exit 0
fi

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
export PATH="$HOME/dotfiles/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# ========== Aliases ==========
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# ========== Powerlevel10k ==========
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
