{
  notebook = {
    system = "x86_64-linux";
    hostName = "notebook";
    user = "wtchrs";

    my.features = {
      desktop.enable = true;
      nvidia.enable = true;
      gaming.enable = true;
    };
  };

  my-nixos = {
    system = "x86_64-linux";
    user = "wtchrs";
    # use the attrName as a default hostName
  };
}
