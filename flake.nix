{
  description = "A shitty flake for setting up Crowdsec.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      nixosModules = {
        crowdsec = import ./modules/crowdsec;
        cs-firewall-bouncer = import ./modules/cs-firewall-bouncer self;
      };
      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in {
          cs-firewall-bouncer = pkgs.callPackage ./pkgs/cs-firewall-bouncer {
            buildGoModule = pkgs.buildGo120Module;
          };
          default = self.packages.${system}.cs-firewall-bouncer;
        });
    };
}
