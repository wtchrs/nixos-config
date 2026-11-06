let
  tailscaleIP = "100.86.102.49";
  domain = "wtchrs.xyz";
in
{
  security.acme = {
    acceptTerms = true;

    defaults = {
      email = "wtchr_@outlook.com";
      dnsProvider = "cloudflare";
      environmentFile = "/var/lib/acme-secrets/cloudflare.env";
    };

    certs."services" = {
      domain = "*.${domain}";
    };
  };

  services.caddy = {
    enable = true;
    openFirewall = false;

    # Define HTTP redirects explicitly
    globalConfig = ''
      auto_https disable_redirects
    '';

    virtualHosts = {
      "git.${domain}" = {
        listenAddresses = [ tailscaleIP ];
        useACMEHost = "services";

        extraConfig = ''
          reverse_proxy 127.0.0.1:8000
        '';
      };

      "atuin.${domain}" = {
        listenAddresses = [ tailscaleIP ];
        useACMEHost = "services";

        extraConfig = ''
          reverse_proxy 127.0.0.1:8888
        '';
      };
    };
  };

  systemd.services.caddy = {
    wants = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
  };
}
