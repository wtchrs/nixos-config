{ flake, ... }:

{
  imports = [ flake.inputs.nereid-shell.homeManagerModules.default ];

  programs.nereid-shell = {
    enable = true;
    niriIntegration.enable = true;
  };
}
