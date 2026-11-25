# List the state that the startup files leave in an interactive shell.
# Each section starts with a "@@<category>" line.
print -r -- '@@aliases'
alias

print -r -- '@@bindkeys'
bindkey -L

print -r -- '@@options'
setopt

print -r -- '@@zstyles'
zstyle -L
