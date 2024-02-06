# idk where im going with this, might return to later...
{ cfg }:
{ config, lib, name, ... }:
let
  inherit (lib) mkOption types;
in {
  options = {
    source = mkOption {
      type = types.str;
      default = "file";
      description = ''
        Type of log to look for. Defaults to file
      '';
    };

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
