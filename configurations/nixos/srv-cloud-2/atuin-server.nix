{
  services.atuin = {
    enable = true;

    host = "0.0.0.0";
    port = 8888;

    # Change to false after create a account
    openRegistration = false;

    openFirewall = false;
    database.createLocally = true;
  };
}
