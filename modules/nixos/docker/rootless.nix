{ username, ... }:

{
  # Rootless docker daemon
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Run services without user login (needed for rootless docker)
  users.users.${username}.linger = true;
}
