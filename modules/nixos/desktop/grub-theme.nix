{ pkgs, ... }:

let
  darkSplash =
    pkgs.runCommand "grub-splash.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick ${../../../assets/wallpaper.jpg} \
          -resize '1920x1080^' \
          -gravity center -extent 1920x1080 \
          -blur 0x12 \
          -channel RGB -evaluate Multiply 0.6 +channel \
          -seed 42 \
          -attenuate 0.01 +noise Uniform \
          "$out"
      '';
in
{
  boot.loader.grub2-theme = {
    enable = true;
    theme = "stylish";
    footer = true;
    customResolution = "1920x1080";
    splashImage = darkSplash;
  };
}
