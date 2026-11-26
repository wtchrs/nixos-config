{
  config,
  lib,
  pkgs,
  ...
}:

let
  atuin = config.programs.atuin.package;

  # `atuin init` prints the same script at every shell start. Generate it once
  # at build time, as Home Manager already does for fish and nushell.
  atuinInit =
    shell:
    pkgs.runCommand "atuin-init.${shell}" { nativeBuildInputs = [ pkgs.writableTmpDirAsHomeHook ]; } ''
      ${lib.getExe atuin} init ${shell} > "$out"
    '';
in
{
  programs.atuin = {
    enable = true;

    # The bash and zsh init below replace these integrations, which run
    # `atuin init` at every shell start.
    enableBashIntegration = false;
    enableZshIntegration = false;

    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.wtchrs.xyz";

      search_mode = "daemon-fuzzy";
      filter_mode = "host";

      daemon = {
        enabled = true;
        autostart = true;
      };

      store_failed = true;
    };
  };

  programs.bash.initExtra = ''
    if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
      source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
      source ${atuinInit "bash"}
    fi
  '';

  programs.zsh.initContent = ''
    if [[ $options[zle] = on ]]; then
      source ${atuinInit "zsh"}
    fi
  '';
}
