{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  pname = "mix2nix";
  version = "0.2.0";

  src = ./.;

  buildInputs = [ erlang ];
  nativeBuildInputs = [ elixir ];

  buildPhase = "mix escript.build";

  installPhase = "install -Dt $out/bin mix2nix";
}
