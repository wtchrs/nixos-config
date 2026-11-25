# Time the work that zsh does before it draws the first prompt.
# Some hooks remove themselves after their first run, so each hook runs once,
# in the order that zsh runs them.
zmodload zsh/datetime

local hook start
local -a hooks
(( $+functions[precmd] )) && hooks=(precmd)
hooks+=($precmd_functions)

for hook in $hooks; do
  start=$EPOCHREALTIME
  {
    $hook
  } >/dev/null 2>&1
  print -r -- "@@${hook}"$'\t'"$(( (EPOCHREALTIME - start) * 1000 ))"
done

start=$EPOCHREALTIME
{
  : ${(%)${(e)PROMPT}} ${(%)${(e)RPROMPT}}
} >/dev/null 2>&1
print -r -- "@@(prompt)"$'\t'"$(( (EPOCHREALTIME - start) * 1000 ))"
