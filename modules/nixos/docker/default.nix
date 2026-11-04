{
  virtualisation.docker = {
    enable = true;
    # Use local logging because Docker's minimal libsystemd cannot read compressed journals
    logDriver = "local";
  };
}
