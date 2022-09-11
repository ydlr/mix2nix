build:
	nix-build

install:
	nix-env -f ./ -i
