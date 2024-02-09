{ lib, buildGoModule, fetchFromGitHub, makeWrapper, ipset }:

buildGoModule rec {
  pname = "cs-firewall-bouncer";
  version = "0.0.28";

  meta = with lib; {
    homepage = "https://www.crowdsec.net/";
    description = "Crowdsec firewall bouncer built for NixOS";
  };

  src = fetchFromGitHub {
    owner = "crowdsecurity";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Y1pCupCtYkOD6vKpcmM8nPlsGbO0kYhc3PC9YjJHeMw=";
  };

  buildInputs = [
    makeWrapper
    ipset
  ];

  vendorHash = "sha256-BA7OHvqIRck3LVgtx7z8qhgueaJ6DOMU8clvWKUCdqE=";

  postInstall = ''
    wrapProgram $out/bin/cs-firewall-bouncer \
      --prefix PATH : ${lib.makeBinPath [ ipset ]}
  '';

  CGO_ENABLED = 0;
  ldflags = [
    "-a"
    "-s"
    "-w"
    "-X 'github.com/crowdsecurity/go-cs-lib/version.Version=v${version}'"
    "-X 'github.com/crowdsecurity/go-cs-lib/version.BuildDate=1970-01-01_00:00:00'"
    "-X 'github.com/crowdsecurity/go-cs-lib/version.Tag=${src.rev}'"
  ];
}
