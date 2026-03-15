# ~/.zshrc
# Seongho's dotfiles — https://github.com/liveseongho/dotfiles

# ========== Guard: zsh only ==========
if [ -z "$ZSH_VERSION" ]; then
  return 0 2>/dev/null || exit 0
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ========== Oh My Zsh ==========
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# ========== zsh-autocomplete (must load before oh-my-zsh) ==========
zstyle ':autocomplete:*' list-lines 5
zstyle ':autocomplete:tab:*' insert-unambiguous yes
if [[ -f ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]]; then
  source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
fi

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

# ========== Environment Modules (HPC/Linux servers) ==========
if [ -f /etc/profile.d/modules.sh ]; then
  source /etc/profile.d/modules.sh
elif [ -f /usr/share/modules/init/zsh ]; then
  source /usr/share/modules/init/zsh
elif [ -f /usr/share/Modules/init/zsh ]; then
  source /usr/share/Modules/init/zsh
fi

# ========== Aliases ==========
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# ========== Powerlevel10k ==========
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
