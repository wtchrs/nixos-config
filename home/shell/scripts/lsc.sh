# eza default color rules expanded to LS_COLORS-style globs

_lsc_add() {
  local style="$1"
  shift

  local key
  for key in "$@"; do
    LS_COLORS="${LS_COLORS:+$LS_COLORS:}${key}=${style}"
  done
}

_lsc_add_lsd_name() {
  local style="$1"
  shift

  local key
  for key in "$@"; do
    # lsd's LS_COLORS parser does not treat bare basenames as filename globs.
    # A leading "*" makes these rules match files ending with the given name.
    _lsc_add "$style" "*${key}"
  done
}

# ------------------------------------------------------------
# Basic file kinds
# ------------------------------------------------------------
_lsc_add '0'     fi       # normal file
_lsc_add '1;34'  di       # directory: blue bold
_lsc_add '36'    ln       # symlink: cyan
_lsc_add '33'    pi       # pipe: yellow
_lsc_add '1;31'  so       # socket: red bold
_lsc_add '1;33'  bd cd    # block/char device: yellow bold
_lsc_add '1;32'  ex       # executable: green bold
_lsc_add '31'    or       # broken symlink: red

# eza mount_point = blue bold underline.
# Standard LS_COLORS does not have a portable mount-point key.
# Some parsers may accept mp, but lsd/GNU ls compatibility is not guaranteed.
_lsc_add '1;4;34' mp

# ------------------------------------------------------------
# eza README prefix rule, approximated with lsd-compatible suffix rules.
# eza treats case-insensitive names starting with "readme" as Build.
# lsd does not apply bracket globs or mid-pattern wildcards here, so keep the
# common README basenames explicit.
# ------------------------------------------------------------
_lsc_add_lsd_name '1;4;33' \
  README \
  README.adoc \
  README.markdown \
  README.md \
  README.mkd \
  README.org \
  README.rst \
  README.txt \
  Readme \
  Readme.adoc \
  Readme.markdown \
  Readme.md \
  Readme.mkd \
  Readme.org \
  Readme.rst \
  Readme.txt \
  readme \
  readme.adoc \
  readme.markdown \
  readme.md \
  readme.mkd \
  readme.org \
  readme.rst \
  readme.txt

# ------------------------------------------------------------
# eza temp filename rules
# name ending in ~, or #...#
# lsd does not handle #*# as a full glob; *# preserves the common Emacs
# autosave suffix case, with the tradeoff that any name ending in # is dimmed.
# ------------------------------------------------------------
_lsc_add '2' '*~' '#*#' '*#'

# ------------------------------------------------------------
# Exact filename rules
# Build: yellow bold underline
# ------------------------------------------------------------
_lsc_add_lsd_name '1;4;33' \
  Brewfile \
  bsconfig.json \
  BUILD \
  BUILD.bazel \
  build.gradle \
  build.sbt \
  build.xml \
  Cargo.toml \
  CMakeLists.txt \
  composer.json \
  configure \
  Containerfile \
  Dockerfile \
  Earthfile \
  flake.nix \
  Gemfile \
  GNUmakefile \
  Gruntfile.coffee \
  Gruntfile.js \
  jsconfig.json \
  Justfile \
  justfile \
  Makefile \
  makefile \
  meson.build \
  mix.exs \
  package.json \
  Pipfile \
  PKGBUILD \
  Podfile \
  pom.xml \
  Procfile \
  pyproject.toml \
  Rakefile \
  RoboFile.php \
  SConstruct \
  tsconfig.json \
  Vagrantfile \
  webpack.config.cjs \
  webpack.config.js \
  WORKSPACE

# Crypto/private key filenames: green bold
_lsc_add_lsd_name '1;32' \
  id_dsa \
  id_ecdsa \
  id_ecdsa_sk \
  id_ed25519 \
  id_ed25519_sk \
  id_rsa

# ------------------------------------------------------------
# Extension rules
# ------------------------------------------------------------

# Build: yellow bold underline
_lsc_add '1;4;33' \
  '*.ninja'

# Image: purple
_lsc_add '35' \
  '*.arw' \
  '*.avif' \
  '*.bmp' \
  '*.cbr' \
  '*.cbz' \
  '*.cr2' \
  '*.dvi' \
  '*.eps' \
  '*.fodg' \
  '*.gif' \
  '*.heic' \
  '*.heif' \
  '*.ico' \
  '*.j2c' \
  '*.j2k' \
  '*.jfi' \
  '*.jfif' \
  '*.jif' \
  '*.jp2' \
  '*.jpe' \
  '*.jpeg' \
  '*.jpf' \
  '*.jpg' \
  '*.jpx' \
  '*.jxl' \
  '*.kra' \
  '*.krz' \
  '*.nef' \
  '*.odg' \
  '*.orf' \
  '*.pbm' \
  '*.pgm' \
  '*.png' \
  '*.pnm' \
  '*.ppm' \
  '*.ps' \
  '*.psd' \
  '*.pxm' \
  '*.raw' \
  '*.qoi' \
  '*.svg' \
  '*.tif' \
  '*.tiff' \
  '*.webp' \
  '*.xcf' \
  '*.xpm'

# Video: purple bold
_lsc_add '1;35' \
  '*.avi' \
  '*.flv' \
  '*.h264' \
  '*.heics' \
  '*.m2ts' \
  '*.m2v' \
  '*.m4v' \
  '*.mkv' \
  '*.mov' \
  '*.mp4' \
  '*.mpeg' \
  '*.mpg' \
  '*.ogm' \
  '*.ogv' \
  '*.video' \
  '*.vob' \
  '*.webm' \
  '*.wmv'

# Music: cyan
_lsc_add '36' \
  '*.aac' \
  '*.m4a' \
  '*.mka' \
  '*.mp2' \
  '*.mp3' \
  '*.ogg' \
  '*.opus' \
  '*.wma'

# Lossless audio: cyan bold
_lsc_add '1;36' \
  '*.aif' \
  '*.aifc' \
  '*.aiff' \
  '*.alac' \
  '*.ape' \
  '*.flac' \
  '*.pcm' \
  '*.wav' \
  '*.wv'

# Crypto/signature/certificate/hash: green bold
_lsc_add '1;32' \
  '*.age' \
  '*.asc' \
  '*.cer' \
  '*.crt' \
  '*.csr' \
  '*.gpg' \
  '*.kbx' \
  '*.md5' \
  '*.p12' \
  '*.pem' \
  '*.pfx' \
  '*.pgp' \
  '*.pub' \
  '*.sha1' \
  '*.sha224' \
  '*.sha256' \
  '*.sha384' \
  '*.sha512' \
  '*.sig' \
  '*.signature'

# Documents: green
_lsc_add '32' \
  '*.djvu' \
  '*.doc' \
  '*.docx' \
  '*.eml' \
  '*.fodp' \
  '*.fods' \
  '*.fodt' \
  '*.fotd' \
  '*.gdoc' \
  '*.key' \
  '*.keynote' \
  '*.numbers' \
  '*.odp' \
  '*.ods' \
  '*.odt' \
  '*.pages' \
  '*.pdf' \
  '*.ppt' \
  '*.pptx' \
  '*.rtf' \
  '*.xls' \
  '*.xlsm' \
  '*.xlsx'

# Compressed/archive/disk images: red
_lsc_add '31' \
  '*.7z' \
  '*.ar' \
  '*.arj' \
  '*.br' \
  '*.bz' \
  '*.bz2' \
  '*.bz3' \
  '*.cpio' \
  '*.deb' \
  '*.dmg' \
  '*.gz' \
  '*.iso' \
  '*.lz' \
  '*.lz4' \
  '*.lzh' \
  '*.lzma' \
  '*.lzo' \
  '*.phar' \
  '*.qcow' \
  '*.qcow2' \
  '*.rar' \
  '*.rpm' \
  '*.tar' \
  '*.taz' \
  '*.tbz' \
  '*.tbz2' \
  '*.tc' \
  '*.tgz' \
  '*.tlz' \
  '*.txz' \
  '*.tz' \
  '*.xz' \
  '*.vdi' \
  '*.vhd' \
  '*.vhdx' \
  '*.vmdk' \
  '*.z' \
  '*.zip' \
  '*.zst'

# Temporary/backup/partial downloads: dim
_lsc_add '2' \
  '*.bak' \
  '*.bk' \
  '*.bkp' \
  '*.crdownload' \
  '*.download' \
  '*.fcbak' \
  '*.fcstd1' \
  '*.fdmdownload' \
  '*.part' \
  '*.swn' \
  '*.swo' \
  '*.swp' \
  '*.tmp'

# Compiled/binary/library artifacts: yellow
_lsc_add '33' \
  '*.a' \
  '*.bundle' \
  '*.class' \
  '*.cma' \
  '*.cmi' \
  '*.cmo' \
  '*.cmx' \
  '*.dll' \
  '*.dylib' \
  '*.elc' \
  '*.elf' \
  '*.ko' \
  '*.lib' \
  '*.o' \
  '*.obj' \
  '*.pyc' \
  '*.pyd' \
  '*.pyo' \
  '*.so' \
  '*.zwc'

# Source code: yellow bold
_lsc_add '1;33' \
  '*.applescript' \
  '*.as' \
  '*.asa' \
  '*.awk' \
  '*.c' \
  '*.c++' \
  '*.c++m' \
  '*.cabal' \
  '*.cc' \
  '*.ccm' \
  '*.clj' \
  '*.cp' \
  '*.cpp' \
  '*.cppm' \
  '*.cr' \
  '*.cs' \
  '*.css' \
  '*.csx' \
  '*.cu' \
  '*.cxx' \
  '*.cxxm' \
  '*.cypher' \
  '*.d' \
  '*.dart' \
  '*.di' \
  '*.dpr' \
  '*.el' \
  '*.elm' \
  '*.erl' \
  '*.ex' \
  '*.exs' \
  '*.f' \
  '*.f90' \
  '*.fcmacro' \
  '*.fcscript' \
  '*.fnl' \
  '*.for' \
  '*.fs' \
  '*.fsh' \
  '*.fsi' \
  '*.fsx' \
  '*.gd' \
  '*.go' \
  '*.gradle' \
  '*.groovy' \
  '*.gvy' \
  '*.h' \
  '*.h++' \
  '*.hh' \
  '*.hpp' \
  '*.hc' \
  '*.hs' \
  '*.htc' \
  '*.hxx' \
  '*.inc' \
  '*.inl' \
  '*.ino' \
  '*.ipynb' \
  '*.ixx' \
  '*.java' \
  '*.jl' \
  '*.js' \
  '*.jsx' \
  '*.kt' \
  '*.kts' \
  '*.kusto' \
  '*.less' \
  '*.lhs' \
  '*.lisp' \
  '*.ltx' \
  '*.lua' \
  '*.m' \
  '*.malloy' \
  '*.matlab' \
  '*.ml' \
  '*.mli' \
  '*.mn' \
  '*.nb' \
  '*.p' \
  '*.pas' \
  '*.php' \
  '*.pl' \
  '*.pm' \
  '*.pod' \
  '*.pp' \
  '*.prql' \
  '*.ps1' \
  '*.psd1' \
  '*.psm1' \
  '*.purs' \
  '*.py' \
  '*.r' \
  '*.rb' \
  '*.rs' \
  '*.rq' \
  '*.sass' \
  '*.scala' \
  '*.scm' \
  '*.scad' \
  '*.scss' \
  '*.sld' \
  '*.sql' \
  '*.ss' \
  '*.swift' \
  '*.tcl' \
  '*.tex' \
  '*.ts' \
  '*.v' \
  '*.vb' \
  '*.vsh' \
  '*.zig'

export LS_COLORS
unset -f _lsc_add _lsc_add_lsd_name
