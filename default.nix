{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
mixNixDeps = import ./nix/mix-deps.nix {
  inherit lib beamPackages;
};

in
beamPackages.mixRelease {
  pname = "mix2nix";
	version = "0.1.6";
  src = ./.;
  inherit mixNixDeps;
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    mkdir -p $out/bin
    wrapProgram $out/bin/mix2nix \
      --set RELEASE_COOKIE REPLACEME \
      --run 'export MIX2NIX_ARGV="$@"' \
      --add-flags "eval 'Mix2nix.CLI.main(System.argv())'"
  '';
}
