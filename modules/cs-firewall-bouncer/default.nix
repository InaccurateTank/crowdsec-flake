flake: { config, lib, pkgs, ... }:

with lib;
let
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) cs-firewall-bouncer;

  cfg = config.services.cs-firewall-bouncer;
  local = (cfg.apiURL == "http://127.0.0.1:8080/");
in {
  options.services.cs-firewall-bouncer = {
    enable = mkEnableOption ''
      CrowdSec bouncer written in golang for firewalls.
    '';

    apiURL = mkOption {
      type = types.string;
      default = "http://127.0.0.1:8080/";
      description = ''
        URL of the Crowdsec API being used.
      '';
    };

    apiKey = mkOption {
      type = with types; nullOr string;
      default = null;
      description = ''
        The key used for connecting to crowdsec API.
      '';
    };

    apiKeyFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        The full filepath to the file that contains the crowdsec API key.
        The file should contain exactly one line, which is the key.
      '';
    };

    package = mkOption {
      type = types.package;
      default = cs-firewall-bouncer;
      description = ''
        The bouncer package to use with the service.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (apiKey != null && apiKeyFile == null) || (apiKey == null && apiKeyFile != null) || local;
        message = "Either a key or a keyfile can be provided, but not both.";
      }
    ];

    networking.firewall.enable = true;

    environment.etc."crowdsec/bouncers/crowdsec-firewall-bouncer.yaml".text = ''
      ## Config managed by NixOS

      mode: ${if config.networking.nftables.enable then "nftables" else "iptables"}
      update_frequency: 10s
      log_mode: file
      log_dir: /var/log/
      log_level: info
      log_compression: true
      log_max_size: 100
      log_max_backups: 3
      log_max_age: 30
      api_url: ${cfg.apiURL}
      api_key: $API_KEY
      insecure_skip_verify: false
      disable_ipv6: false
      deny_action: DROP
      deny_log: false
      supported_decisions_types:
        - ban
      #to change log prefix
      #deny_log_prefix: "crowdsec: "
      #to change the blacklists name
      blacklists_ipv4: crowdsec-blacklists
      blacklists_ipv6: crowdsec6-blacklists
      #type of ipset to use
      ipset_type: nethash
      #if present, insert rule in those chains
      iptables_chains:
        - INPUT
      #  - FORWARD
      #  - DOCKER-USER

      ## nftables
      nftables:
        ipv4:
          enabled: true
          set-only: false
          table: crowdsec
          chain: crowdsec-chain
          priority: -10
        ipv6:
          enabled: true
          set-only: false
          table: crowdsec6
          chain: crowdsec6-chain
          priority: -10

      nftables_hooks:
        - input
        - forward

      # packet filter
      pf:
        # an empty string disables the anchor
        anchor_name: ""

      prometheus:
        enabled: false
        listen_addr: 127.0.0.1
        listen_port: 60601
    '';

    systemd.services."cs-firewall-bouncer" = {
      description = "The firewall bouncer for CrowdSec";
      wantedBy = [ "multi-user.target" ];
      after = [
        "syslog.target"
        "network.target"
        "remote-fs.target"
        "nss-lookup.target"
        "crowdsec.service"
      ];
      preStart = let
        body = ''
          APIKEY=${if (local && config.services.crowdsec.enable) then ''${cfg.package}/bin/cscli -oraw bouncers add "cs-firewall-bouncer-$(date +%s)"''
          else if (apiKey != null) then ''${apiKey}''
          else ''cat ${apiKeyFile}''
          }
          echo "api_key: $APIKEY" | install -D -m 0600 /dev/stdin "/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.local"
        '';
      in ''
        ${if (local && local && config.services.crowdsec.enable) then ''
          if [ ! -f /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml.local ]; then
            ${body}
          fi
        ''
        else body}
        ${cfg.package}/bin/cs-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -t
      '';
      serviceConfig = {
        Type = "notify";
        ExecStart = "${cfg.package}/bin/cs-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml";
        Restart = "always";
        RestartSec = 10;
        LimitNOFILE = 65536;
        KillMode = "mixed";
      };
    };
  };
}
