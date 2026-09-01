{ pkgs, ... }:

let
  nordColors = ''
    [colors]
    completion-menu.completion.current = 'bg:#88c0d0 #2e3440'
    completion-menu.completion = 'bg:#3b4252 #d8dee9'
    completion-menu.meta.completion.current = 'bg:#81a1c1 #2e3440'
    completion-menu.meta.completion = 'bg:#434c5e #d8dee9'
    completion-menu.multi-column-meta = 'bg:#4c566a #eceff4'
    scrollbar.arrow = 'bg:#3b4252'
    scrollbar = 'bg:#4c566a'
    selected = '#eceff4 bg:#5e81ac'
    search = '#2e3440 bg:#ebcb8b'
    search.current = '#2e3440 bg:#a3be8c'
    bottom-toolbar = 'bg:#3b4252 #d8dee9'
    bottom-toolbar.off = 'bg:#3b4252 #4c566a'
    bottom-toolbar.on = 'bg:#3b4252 #eceff4'
    search-toolbar = 'noinherit bold #ebcb8b'
    search-toolbar.text = 'nobold #d8dee9'
    system-toolbar = 'noinherit bold #88c0d0'
    arg-toolbar = 'noinherit bold #b48ead'
    arg-toolbar.text = 'nobold #d8dee9'
    bottom-toolbar.transaction.valid = 'bg:#3b4252 #a3be8c bold'
    bottom-toolbar.transaction.failed = 'bg:#3b4252 #bf616a bold'
    output.header = '#88c0d0 bold'
    output.odd-row = '#d8dee9'
    output.even-row = '#d8dee9'
    output.null = '#4c566a'
  '';
in

{
  home.packages = with pkgs; [
    mycli
    pgcli
  ];

  xdg.configFile."pgcli/config".text = ''
    [main]
    smart_completion = True
    multi_line = True
    destructive_warning = True
    keyword_casing = upper
    timing = True
    table_format = psql
    auto_expand = True
    less_chatty = False
    enable_pager = False
    syntax_style = nord

    ${nordColors}
  '';

  home.file.".myclirc".text = ''
    [main]
    smart_completion = True
    multi_line = True
    destructive_warning = True
    keyword_casing = upper
    timing = True
    table_format = mysql_unicode
    auto_vertical_output = True
    less_chatty = False
    enable_pager = False
    syntax_style = nord

    ${nordColors}

    [connection]
    default_character_set = utf8mb4
  '';
}
