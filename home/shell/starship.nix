_:

{
  programs.starship = {
    enable = true;

    settings = {
      format = let
        start = "[ ](bg:#445167)[ ](bg:#62708a)[ ](bg:#808eaf)";
        split1 = "[](bg:#769ff0 fg:#a3aed2)";
        split2 = "[](fg:#769ff0 bg:#394260)";
        split3 = "[](fg:#394260 bg:#212736)";
        split4 = "[](fg:#212736 bg:#1d2230)";
        split5 = "[](fg:#1d2230)";
        new_line = "\n";
      in
        start + ''$os$shell'' + split1 + ''$directory'' + split2 +
        ''$git_branch$git_status'' + split3 + ''$nodejs$rust$golang$php'' +
        split4 + ''$time'' + split5 + ''$nix_shell'' + new_line + ''$character'';

      continuation_prompt = "[ ](#62708a)";

      os = {
        format = "[ $symbol ](bold bg:#a3aed2 fg:#090c0c)";
        disabled = false;
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = "󰍲 ";
        };
      };

      shell = {
        disabled = false;
        format = "[$indicator ]($style)";
        style = "bold bg:#a3aed2 fg:#090c0c";
      };

      username = {
        style_user = "bg:#a3aed2 fg:#090c0c";
        style_root = "bg:#a3aed2 fg:red bold";
        format = "[ $user ]($style)";
        disabled = false;
        show_always = true;
      };

      directory = {
        style = "fg:#1d2230 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "… /";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = " ";
          Pictures = " ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = ''[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'';
      };

      git_status = {
        style = "bg:#394260";
        format = ''[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'';
      };

      nix_shell = {
        disabled = false;
        style = "bg:#212736";
        impure_msg = "[impure](fg:bold red)";
        pure_msg = "[pure](fg:bold green)";
        unknown_msg = "[unknown](fg:bold yellow)";
        format = " via [ $state( \($name\))](fg:bold blue)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#212736";
        format = ''[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'';
      };

      rust = {
        symbol = "";
        style = "bg:#212736";
        format = ''[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'';
      };

      golang = {
        symbol = "";
        style = "bg:#212736";
        format = ''[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'';
      };

      php = {
        symbol = "";
        style = "bg:#212736";
        format = ''[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'';
      };

      time = {
        disabled = false;
        time_format = "%R"; # Hour:Minute Format
        style = "bg:#1d2230";
        format = ''[[   $time ](fg:#a0a9cb bg:#1d2230)]($style)'';
      };

      character = {
        success_symbol = "[•](#a3aed2)";
        error_symbol = "[•](red)";
      };
    };
  };
}
