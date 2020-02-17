{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
	pname = "mix2nix";
	version = "0.1.0";

	src = ./.;

	buildInputs = [ elixir erlang ];
	buildPhase = "mix escript.build";

	installPhase = "install -Dt $out/bin mix2nix";
}