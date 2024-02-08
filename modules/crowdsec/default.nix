{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.crowdsec;
in {
  options.services.crowdsec = {
    enable = mkEnableOption ''
      CrowdSec agent.
    '';

    acquisEntries = mkOption {
      type = with types; attrsOf lines;
      default = [];
      description = ''
        A list of entries for acquis.yaml. Tells Crowdsec what files to monitor.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.crowdsec;
      description = ''
        The Crowdsec package to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Added purely for cscli. Collections should be managed through config, but cscli provides monitoring tools.
    environment.systemPackages = [cfg.package];

    system.activationScripts.crowdsecInit = lib.stringAfter [ "var" ] ''
      mkdir -p /var/lib/crowdsec/data
      mkdir -p /etc/crowdsec/hub
    '';

    environment.etc = {
      "crowdsec/config.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/config.yaml";
        mode = "0600";
      };
      "crowdsec/profiles.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/profiles.yaml";
        mode = "0644";
      };
      "crowdsec/simulation.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/simulation.yaml";
        mode = "0644";
      };
      "crowdsec/patterns".source = "${cfg.package}/share/crowdsec/config/patterns";
      "crowdsec/acquis.yaml".text = ''
        # Generated by NixOS
        ${concatStringsSep "---\n" (mapAttrsToList (name: value: ''
          # ${name}
          ${value}
        '') cfg.acquisEntries)}
      '';
    };

    services.crowdsec.acquisEntries = {
      "sshd" = mkIf config.services.openssh.enable ''
        journalctl_filter:
         - _SYSTEMD_UNIT=sshd.service
        labels:
          type: syslog
      '';
      "caddy" = mkIf config.services.caddy.enable ''
        filenames:
         - /var/log/caddy/*.log
        labels:
          type: caddy
      '';
    };

    systemd.services."crowdsec" = {
      description = "Crowdsec agent";
      wantedBy = [ "multi-user.target" ];
      after = [
        "syslog.target"
        "network.target"
        "remote-fs.target"
        "nss-lookup.target"
      ];
      environment = {
        LC_ALL = "C";
        LANG = "C";
      };
      preStart = ''
        ${cfg.package}/bin/cscli hub update
        ${cfg.package}/bin/cscli hub upgrade

        ${cfg.package}/bin/cscli collections install crowdsecurity/linux

        if [ ! -e /etc/crowdsec/local_api_credentials.yaml ]; then
          install -v -m 600 -D "${cfg.package}/share/crowdsec/config/local_api_credentials.yaml" "/etc/crowdsec"
          ${cfg.package}/bin/cscli machines add --force "$(cat /etc/machine-id)" -a -f "/etc/crowdsec/local_api_credentials.yaml"
        fi

        if [ ! -e /etc/crowdsec/online_api_credentials.yaml ]; then
          install -v -m 600 -D "${cfg.package}/share/crowdsec/config/online_api_credentials.yaml" "/etc/crowdsec"
          ${cfg.package}/bin/cscli capi register --error
        fi

        ${cfg.package}/bin/crowdsec -c /etc/crowdsec/config.yaml -t -error
      '';
      serviceConfig = {
        Type = "notify";
        ExecStart = "${cfg.package}/bin/crowdsec -c /etc/crowdsec/config.yaml";
        ExecReload = "/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 60;
      };
    };
  };
}
