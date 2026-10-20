{ pkgs, ... }:

{
  home.packages = with pkgs; [
    typst
    typstyle
    tinymist
    hugo

    poppler-utils
    mupdf
    tesseract
    ghostscript
    imagemagick
    pandoc
    exiftool
    ripgrep
  ];
}
