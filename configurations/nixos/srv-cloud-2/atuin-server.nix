{
  services.atuin = {
    enable = true;

    host = "127.0.0.1";
    port = 8888;

    # Change to false after create a account
    openRegistration = false;

    openFirewall = false;
    database.createLocally = true;
  };
}
