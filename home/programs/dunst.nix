{ ... } :

{
  services.dunst = {
    enable = true;

    settings = {
      global = {
        follow = "mouse";
        geometry = "300x30-5+60";
        indicate_hidden = true;
        shrink = false;
        transparency = 0;
        notification_height = 0;
        height = "(0, 200)";
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        frame_width = 1;
        frame_color = "#4287f5";
        sort = true;
        idle_threshold = 0;

        font = "Iosevka 10";
        line_height = 0;
        markup = "full";
        format = "<b>%a</b>\n<i>%s</i>\n%b";
        alignment = "center";
        vertical_alignment = "center";
        show_age_threshold = -1;
        word_wrap = true;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = true;
        show_indicators = false;

        icon_position = "off";

        history_length = 20;

        # dmenu = "/usr/bin/dmenu -p dunst:";
        # browser = "/usr/bin/firefox -new-tab";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        startup_notification = false;
        verbosity = "mesg";
        corner_radius = 15;
        ignore_dbusclose = false;

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action";
        mouse_right_click = "do_action";
      };

      shortcuts = {
        close = "ctrl+space";
        close_all = "ctrl+shift+space";
      };

      urgency_normal = {
        background = "#202632";
        foreground = "#ffffff";
        timeout = 5;
      };

      urgency_critical = {
        background = "#ffffff";
        foreground = "#db0101";
        timeout = 0;
      };
    };
  };
}
