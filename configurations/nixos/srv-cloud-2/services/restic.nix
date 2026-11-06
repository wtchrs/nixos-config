{ config, pkgs, ... }:

{
  services.postgresqlBackup = {
    enable = true;
    databases = [ "atuin" ];

    # Run the dump from the restic preparation step.
    startAt = [ ];
  };

  services.restic.backups.services-r2 = {
    # Create `/etc/restic/r2.env`:
    #   RESTIC_REPOSITORY=s3:https://<account-id>.r2.cloudflarestorage.com/<bucket>/srv-cloud-2
    #   AWS_ACCESS_KEY_ID=<R2-access-key-id>
    #   AWS_SECRET_ACCESS_KEY=<R2-secret-access-key>
    #   AWS_DEFAULT_REGION=auto
    environmentFile = "/etc/restic/r2.env";

    # Write your one-line restic repository password
    # in `/etc/restic/srv-cloud-2.password`
    passwordFile = "/etc/restic/srv-cloud-2.password";

    initialize = true;

    paths = [
      "/var/backup/restic-stage/forgejo"
      "/var/backup/postgresql/atuin.sql.gz"
    ];

    extraBackupArgs = [
      "--host srv-cloud-2"
      "--tag services"
    ];

    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      RandomizedDelaySec = "15m";
      Persistent = true;
    };

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 12"
    ];

    runCheck = true;

    backupPrepareCommand = ''
      #!${pkgs.runtimeShell}
      set -euo pipefail
      umask 077

      # Abort the backup if the database dump fails.
      systemctl start postgresqlBackup-atuin.service

      install -d -m 0700 /var/backup/restic-stage
      install -d -m 0700 /var/backup/restic-stage/forgejo

      was_active=0
      if systemctl is-active --quiet forgejo.service; then
        was_active=1
        trap 'systemctl start forgejo.service' EXIT
        systemctl stop forgejo.service
      fi

      rsync --archive --delete \
        ${config.services.forgejo.stateDir}/ \
        /var/backup/restic-stage/forgejo/

      if [ "$was_active" -eq 1 ]; then
        systemctl start forgejo.service
        trap - EXIT
      fi
    '';
  };

  systemd.services.restic-backups-services-r2.path = [
    pkgs.coreutils
    pkgs.rsync
    pkgs.systemd
  ];
}
