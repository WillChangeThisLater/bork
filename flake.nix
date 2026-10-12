{
  description = "bork: paul's python utility";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.bork = pkgs.runCommand "bork" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      mkdir -p $out/bin
      install -m755 ${./bin/bork} $out/bin/bork
      wrapProgram $out/bin/bork --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.python3 ]}
    '';
    packages.x86_64-linux.default = self.packages.x86_64-linux.bork;
  };
}