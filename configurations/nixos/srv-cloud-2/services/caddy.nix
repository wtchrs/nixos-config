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
      dnsResolver = "1.1.1.1:53";
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

  # The vhosts bind to the Tailscale IP. tailscaled reports ready before tailscale0
  # has that IP, and the caddy unit does not restart after a failed bind (exit 1).
  # tailscale-online.target waits for the IP; nothing else starts it, so want it here.
  systemd.services.caddy = {
    wants = [ "tailscale-online.target" ];
    after = [ "tailscale-online.target" ];
  };
}
