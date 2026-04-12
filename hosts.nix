{
  system = {
    notebook = {
      system = "x86_64-linux";
      hostName = "notebook-nixos";
      user = "wtchrs";

      my.features = {
        desktop.enable = true;
        nvidia.enable = true;
        gaming.enable = true;
      };
    };

    vm = {
      system = "x86_64-linux";
      user = "wtchrs";
      # use the attrName as a default hostName
    };
  };

  home = {
    notebook = {
      system = "x86_64-linux";
      hostName = "archlinux";
      user = "wtchrs";
      homeDirectory = "/home/wtchrs";
      stateVersion = "26.05";
      profileName = "wtchrs@archlinux";

      my.features = {
        desktop.enable = true;
        nvidia.enable = true;
        gaming.enable = true;
      };
    };

    server = {
      system = "aarch64-linux";
      user = "wtchrs";
    };
  };
}
