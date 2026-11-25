# List the state that the startup files leave in an interactive shell.
# Each section starts with a "@@<category>" line.
print -r -- '@@aliases'
alias

print -r -- '@@bindkeys'
bindkey -L

print -r -- '@@options'
setopt

# One "<pattern> <style>\t<values>" line per style, so that compare can tell
# a changed value from an added or removed style. The (q+) quoting keeps
# spaces and newlines inside a pattern or a value from splitting the line.
print -r -- '@@zstyles'
local pattern style
local -a patterns styles values
zstyle -g patterns
for pattern in $patterns; do
  zstyle -g styles $pattern
  for style in $styles; do
    zstyle -g values $pattern $style
    print -r -- "${(q+)pattern} ${(q+)style}"$'\t'"${(j: :)${(@q+)values}}"
  done
done
