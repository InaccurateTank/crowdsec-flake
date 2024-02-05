{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.crowdsec;

  acquisFile = pkgs.writeTextDir "acquis.yaml" ''
    ${builtins.readFile "${cfg.package}/share/crowdsec/config/acquis.yaml"}
    ---
  '';
in {
  options.services.crowdsec = {
    enable = mkEnableOption ''
      CrowdSec agent.
    '';

    # acquisEntries = mkOption {
    #   types = with types; nullOr string;
    #   default = null;
    # };

    package = mkOption {
      type = types.package;
      default = pkgs.crowdsec;
      description = ''
        The Crowdsec package to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    system.activationScripts.crowdsecInit = lib.stringAfter [ "var" ] ''
      set -eu

      mkdir -p /var/lib/crowdsec/data
      mkdir -p /etc/crowdsec/scenarios
      mkdir -p /etc/crowdsec/postoverflows
      mkdir -p /etc/crowdsec/collections
      mkdir -p /etc/crowdsec/appsec-configs
      mkdir -p /etc/crowdsec/appsec-rules
      mkdir -p /etc/crowdsec/hub
      mkdir -p /usr/local/lib/crowdsec/plugins
      mkdir -p /etc/crowdsec/notifications

      cscli hub update
      cscli machines add --force "$(cat /etc/machine-id)" -a -f "/etc/crowdsec/local_api_credentials.yaml"
    '';

    environment.etc = {
      "crowdsec/config.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/config.yaml";
        mode = "0600";
      };
      "crowdsec/dev.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/dev.yaml";
        mode = "0644";
      };
      "crowdsec/user.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/user.yaml";
        mode = "0644";
      };
      "crowdsec/acquis.yaml" = {
        source = acquisFile;
        mode = "0644";
      };
      "crowdsec/profiles.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/profiles.yaml";
        mode = "0644";
      };
      "crowdsec/simulation.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/simulation.yaml";
        mode = "0644";
      };
      "crowdsec/console.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/console.yaml";
        mode = "0644";
      };
      "crowdsec/console/context.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/context.yaml";
        mode = "0644";
      };
      "crowdsec/patterns".source = "${cfg.package}/share/crowdsec/config/patterns";
      "crowdsec/local_api_credentials.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/local_api_credentials.yaml";
        mode = "0600";
      };
      "crowdsec/online_api_credentials.yaml" = {
        source = "${cfg.package}/share/crowdsec/config/online_api_credentials.yaml";
        mode = "0600";
      };
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
      serviceConfig = {
        Type = "notify";
        ExecStart = "${cfg.package}/bin/crowdsec -c /etc/crowdsec/config.yaml";
        ExecStartPre = "${cfg.package}/bin/crowdsec -c /etc/crowdsec/config.yaml -t -error";
        ExecReload = "/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 60;
      };
    };
  };
}
