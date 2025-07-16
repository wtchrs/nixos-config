{ config, pkgs, ... } :

{
  programs.git = {
    # FIX replace user configurations with your own configurations
    userName = "wtchrs";
    userEmail = "wtchr_@hotmail.com";
  };
}
