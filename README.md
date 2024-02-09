Pre-emptive if you stumbled on this repo: Please don't trust my configs. Theres *gotta* be a better way to make this?

Crowdsec has a nix package but no modules, this flake is an attempt to fix some of that. When the module is included and the service is enabled it will do some setup to get the install at least partially working. The flake also includes a cs-firewall-bouncer package/module for actual bouncer work.

Some limitations:
- For some ungodly reason crowdsec can't be reliably installed without `cscli`. `cscli` can't be run without `config.yaml` which gets linked over *after* the activation script. If you try without, the thing fucking kernel panics.
- As a result of the first thing you functionally need to re-install the entire service as a preStart script. Some of this can be mitigated with if statements, but the fact remains that crowdsec installs arn't deterministic.
- Collections, Parsers and Scenarios are installed in this script via `cscli` but once installed can't be *uninstalled*. This is due to a fair chunk of the install being persistant files rather than store links.
- `config.yaml` isn't modified in any way from the package config. Frankly I don't know how one would even do that without causing issues (see: leaking secrets into the nix store).
