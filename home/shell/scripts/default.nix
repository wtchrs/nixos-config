pkgs:
{
  lsc = pkgs.writeText "lsc.sh" (builtins.readFile ./lsc.sh);
}
