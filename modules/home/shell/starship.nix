# Based on original gist by aiden1999
# Source: https://gist.github.com/aiden1999/509a54e7665c6da1b115c24686eac14c

{ lib, ... }:

{
  programs.starship = {
    enable = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = lib.concatStrings [
        "[](nord10)"
        "$os$username[@](bg:nord10 fg:nord0)$hostname$sudo$nix_shell$shlvl"
        "[](bg:nord9 fg:nord10)"
        "$directory"
        "[](bg:nord8 fg:nord9)"
        "$git_branch$git_metrics$git_status"
        "[](bg:nord7 fg:nord8)"
        "($package$bun$c$cmake$deno$dotnet$elixir$erlang$gleam$golang$haskell"
        "$helm$java$julia$kotlin$gradle$lua$nodejs$php$python$ruby$rust"
        "$scala$swift$terraform$typst$vagrant$zig[ ](fg:nord0 bg:nord7))"
        "[](bg:nord4 fg:nord7)"
        "$cmd_duration"
        "[](bg:none fg:nord4)"

        "$line_break"

        "$character"
      ];

      continuation_prompt = "[  ](#62708a)";
      palette = "nord";

      palettes.nord = {
        nord0 = "#2E3440";
        nord1 = "#3B4252";
        nord2 = "#434C5E";
        nord3 = "#4C566A";
        nord4 = "#D8DEE9";
        nord5 = "#E5E9F0";
        nord6 = "#ECEFF4";
        nord7 = "#8FBCBB";
        nord8 = "#88C0D0";
        nord9 = "#81A1C1";
        nord10 = "#5E81AC";
        nord11 = "#BF616A";
        nord13 = "#EBCB8B";
        nord14 = "#A2BE8A";
      };

      git_branch = {
        format = "[ $symbol$branch(:$remote_branch) ]($style)";
        symbol = "󰘬 ";
        style = "fg:nord0 bg:nord8";
      };

      git_metrics = {
        format = "[+$added/-$deleted ](fg:nord0 bg:nord8)";
        disabled = true;
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style)";
        style = "fg:nord0 bg:nord8";

        modified = " \${count} ";
        staged = " \${count} ";
        renamed = " \${count} ";
        deleted = " \${count} ";
        ahead = " \${count} ";
        behind = " \${count} ";
        diverged = "  \${ahead_count} \${behind_count} ";
        up_to_date = " ";
        untracked = " \${count} ";
        stashed = " \${count} ";
        typechanged = "  ";
        conflicted = " \${count} ";
      };

      nix_shell = {
        disabled = false;
        impure_msg = "";
        symbol = " ";
        style = "fg:nord0 bg:nord10";
        format = "[$symbol$state]($style)";
      };

      shlvl = {
        disabled = false;
        symbol = "";
        style = "fg:nord0 bg:nord10";
        format = "[$symbol$shlvl]($style)";
      };

      bun = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      c = {
        symbol = " ";
        format = "[ $symbol($version(-$name))]($style)";
        style = "fg:nord0 bg:nord7";
      };

      cpp = {
        symbol = " ";
        format = "[ $symbol($version(-$name))]($style)";
        style = "fg:nord0 bg:nord7";
      };

      cmake = {
        symbol = "󰔷 ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      deno = {
        symbol = "🦕 ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      dotnet = {
        symbol = " ";
        format = "[ $symbol($version)( $tfm)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      elixir = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      erlang = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      gleam = {
        symbol = "⭐ ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      golang = {
        symbol = " ";
        format = "[ $symbol($version)( mod $mod_version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      haskell = {
        symbol = " ";
        format = "[ $symbol($ghc_version)( $snapshot)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      helm = {
        symbol = "⎈ ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      java = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      julia = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      kotlin = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      gradle = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      lua = {
        symbol = "󰢱 ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      python = {
        symbol = "󰌠 ";
        format = "[ $symbol$pyenv_prefix($version)(\\($virtualenv\\))]($style)";
        style = "fg:nord0 bg:nord7";
      };

      nodejs = {
        symbol = " ";
        format = "[ $symbol($version)( req $engines_version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      php = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      ruby = {
        symbol = " ";
        format = "[ $symbol($version)(@$gemset)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      rust = {
        symbol = " ";
        format = "[ $symbol($numver)(-$toolchain)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      scala = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      swift = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      terraform = {
        symbol = " ";
        format = "[ $symbol$workspace( $version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      typst = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      vagrant = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      zig = {
        symbol = " ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      package = {
        symbol = "󰏗 ";
        format = "[ $symbol($version)]($style)";
        style = "fg:nord0 bg:nord7";
      };

      hostname = {
        ssh_only = false;
        style = "fg:nord0 bg:nord10";
        format = "[$ssh_symbol$hostname ]($style)";
        ssh_symbol = " ";
      };

      os = {
        style = "fg:nord0 bg:nord10";
        disabled = false;

        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          AOSC = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
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
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "fg:nord0 bg:nord10";
      };

      directory = {
        style = "fg:nord0 bg:nord9";
        read_only = " ";
        format = "[ 󰉋 $path ]($style)[$read_only]($read_only_style)";
        read_only_style = "fg:nord0 bold bg:nord9";
      };

      sudo = {
        disabled = false;
        symbol = " ";
        style = "fg:nord0 bg:nord10";
        format = "[$symbol]($style)";
      };

      cmd_duration = {
        format = "[ 󰔚 $duration ]($style)";
        style = "fg:nord0 bg:nord4";
      };

      character = {
        success_symbol = "[ •](green)";
        error_symbol = "[ •](red)";
        vimcmd_symbol = "[  •](green)";
      };
    };
  };
}
