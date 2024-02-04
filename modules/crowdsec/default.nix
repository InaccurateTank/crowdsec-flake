{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.crowdsec;
  store = pkgs.crowdsec;
in {
  options.services.crowdsec = {
    enable = mkEnableOption ''
      CrowdSec agent.
    '';
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      crowdsec
    ];

    environment.etc = {
      "crowdsec/config.yaml" = {
        source = "${store}/share/crowdsec/config/config.yaml";
        mode = 0600;
      };
      "crowdsec/dev.yaml" = {
        source = "${store}/share/crowdsec/config/dev.yaml";
        mode = 0644;
      };
      "crowdsec/user.yaml" = {
        source = "${store}/share/crowdsec/config/user.yaml";
        mode = 0644;
      };
      "crowdsec/acquis.yaml" = {
        source = "${store}/share/crowdsec/config/acquis.yaml";
        mode = 0644;
      };
      "crowdsec/profiles.yaml" = {
        source = "${store}/share/crowdsec/config/profiles.yaml";
        mode = 0644;
      };
      "crowdsec/simulation.yaml" = {
        source = "${store}/share/crowdsec/config/simulation.yaml";
        mode = 0644;
      };
      "crowdsec/console.yaml" = {
        source = "${store}/share/crowdsec/config/console.yaml";
        mode = 0644;
      };
      "crowdsec/context.yaml" = {
        source = "${store}/share/crowdsec/config/context.yaml";
        mode = 0644;
      };
      "crowdsec/patterns".source = "${store}/share/crowdsec/config/patterns";
      "crowdsec/local_api_credentials.yaml" = {
        source = "${store}/share/crowdsec/config/local_api_credentials.yaml";
        mode = 0600;
      };
      "crowdsec/online_api_credentials.yaml" = {
        source = "${store}/share/crowdsec/config/online_api_credentials.yaml";
        mode = 0600;
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
        ExecStart = "${store}/bin/crowdsec -c /etc/crowdsec/config.yaml";
        ExecStartPre = "${store}/bin/crowdsec -c /etc/crowdsec/config.yaml -t -error";
        ExecReload = "/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = 60;
      };
    };
  };
}
