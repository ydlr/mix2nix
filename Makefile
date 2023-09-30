build:
	nix-build

test:
	nix-shell --run "mix test"

install:
	nix-env -f ./ -i

.PHONY: build test install
