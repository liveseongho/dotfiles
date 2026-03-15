# ~/.bashrc
# Seongho's dotfiles — auto-switch to zsh if available

if [ -t 1 ] && [ -n "$PS1" ] && command -v zsh >/dev/null 2>&1; then
  exec zsh -l
fi
