let
  gitDomain = "git.wtchrs.xyz";
in
{
  services.forgejo = {
    enable = true;
    database.type = "sqlite3";

    settings = {
      server = {
        DOMAIN = gitDomain;
        ROOT_URL = "https://${gitDomain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 8000;
        DISABLE_SSH = true;
      };

      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
      actions.ENABLED = false;
    };
  };
}
