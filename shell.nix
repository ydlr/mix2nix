{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.elixir
    pkgs.erlang

    # keep this line if you use bash
    pkgs.bashInteractive
  ];
}
