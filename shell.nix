{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.elixir

    # keep this line if you use bash
    pkgs.bashInteractive
  ];
}
