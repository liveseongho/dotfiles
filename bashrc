# ~/.bashrc
# Seongho's dotfiles — auto-switch to zsh if available

# Load local config first (conda init, module load, etc.)
[ -f ~/.bashrc.local ] && source ~/.bashrc.local

if [ -t 1 ] && [ -n "$PS1" ] && command -v zsh >/dev/null 2>&1; then
  exec zsh -l
fi
