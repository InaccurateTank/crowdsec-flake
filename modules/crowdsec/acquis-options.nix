{ cfg }:
{ config, lib, name, ... }:
let
  inherit (lib) mkOption types;
in {
  options = {
    filenames = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        List of full paths to log files that will be scanned by Crowdsec.
      '';
    };
    type = mkOption {
      type = types.str;
      default = "syslog";
      description = ''
        Type of log that is being read.
      '';
    };
  };
}
