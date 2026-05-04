{
  lib,
  config,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.features.desktop.enable {
    fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;

      packages = with pkgs; [
        sarasa-gothic
        sarasa-mono-k-nerd-font
        nerd-fonts.symbols-only
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        source-code-pro
        source-han-mono
        source-han-sans
        source-han-serif
        font-awesome
        fira-sans
        fira-code
      ];

      fontconfig = {
        enable = true;
        localConf = ''
          <fontconfig>
            <alias>
              <family>Sarasa Mono K</family>
              <accept>
                <family>Symbols Nerd Font Mono</family>
                <family>Noto Color Emoji</family>
              </accept>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
