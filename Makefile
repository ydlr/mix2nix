build:
	nix build

test:
	nix-shell --run "mix test"

install:
	nix profile install

dev:
	nix develop

.PHONY: build test install dev
