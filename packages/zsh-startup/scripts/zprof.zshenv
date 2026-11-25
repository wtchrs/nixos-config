# zsh reads this file as $ZDOTDIR/.zshenv because zsh-startup points ZDOTDIR
# at a temporary directory. It loads zprof before any startup file runs, then
# restores ZDOTDIR so that zsh reads the user's own .zshrc next.
zmodload zsh/zprof

ZDOTDIR=${ZSH_STARTUP_ZDOTDIR:-$HOME}
unset ZSH_STARTUP_ZDOTDIR

if [[ -r $ZDOTDIR/.zshenv ]]; then
  source $ZDOTDIR/.zshenv
fi
