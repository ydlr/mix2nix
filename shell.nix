{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.elixir

    # keep this line if you use bash
    pkgs.bashInteractive
  ];
}
