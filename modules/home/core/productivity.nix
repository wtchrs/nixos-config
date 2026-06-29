{ pkgs, ... }: {
  home.packages = with pkgs; [
    poppler-utils
    mupdf
    binutils
    tesseract
    ghostscript
    imagemagick
    pandoc
    exiftool
    ripgrep
  ];
}
