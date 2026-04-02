_:

{
  programs.fastfetch = {
    enable = true;

    settings = {
      modules = [
        "break"

        {
          type = "custom";
          format = "┌────────────────────── Hardware ──────────────────────┐";
          outputColor = "red";
        }

        {
          type = "title";
          key = " PC";
          keyColor = "green";
        }

        {
          type = "cpu";
          key = "  󰍛 CPU";
          showPeCoreCount = true;
          format = "{1}";
          keyColor = "green";
        }

        {
          type = "gpu";
          key = "  󰍛 GPU";
          keyColor = "green";
        }

        {
          type = "memory";
          key = "  󰍛 Memory";
          keyColor = "green";
        }

        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────┘";
          outputColor = "red";
        }

        {
          type = "custom";
          format = "┌────────────────────── Software ──────────────────────┐";
          outputColor = "red";
        }

        {
          type = "os";
          key = " OS";
          keyColor = "yellow";
        }

        {
          type = "kernel";
          key = "   Kernel";
          keyColor = "yellow";
        }

        {
          type = "packages";
          key = "  󰏖 Packages";
          keyColor = "yellow";
        }

        {
          type = "shell";
          key = "   Shell";
          keyColor = "yellow";
        }

        {
          type = "command";
          key = "   OS Age";
          keyColor = "yellow";
          text = ''
            birth_install=$(stat -c %W /)
            current=$(date +%s)
            time_progression=$((current - birth_install))
            days_difference=$((time_progression / 86400))
            echo $days_difference days
          '';
        }

        {
          type = "uptime";
          key = "   Uptime";
          keyColor = "yellow";
        }

        {
          type = "de";
          key = " DE";
          keyColor = "blue";
        }

        {
          type = "lm";
          key = "   LM";
          keyColor = "blue";
        }

        {
          type = "wm";
          key = "   WM";
          keyColor = "blue";
        }

        {
          type = "gpu";
          key = "  󰍛 GPU Driver";
          format = "{3}";
          keyColor = "blue";
        }

        {
          type = "wmtheme";
          key = "  󰉼 Theme";
          keyColor = "blue";
        }

        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────┘";
          outputColor = "red";
        }

        {
          type = "custom";
          format = "               {#90}  {#31}  {#32}  {#33}  {#34}  {#35}  {#36}  {#37} ";
        }

        "break"
      ];
    };
  };
}
