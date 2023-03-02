{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

with pkgs;

beamPackages.mixRelease {
  pname = "mix2nix";
  version = "0.1.6";
  src = ./.;
  nativeBuildInputs = [
    makeWrapper
  ];
  postInstall = ''
    mkdir -p $out/bin
    wrapProgram $out/bin/mix2nix \
      --set RELEASE_COOKIE REPLACEME \
      --run 'export MIX2NIX_ARGV="$@"' \
      --add-flags "eval 'Mix2nix.CLI.main(System.argv())'"
  '';
}
