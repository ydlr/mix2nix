# Mix2nix
Generate a set of nix derivations from a mix.lock file.

## Overview

Mix2nix is a command line utility to create a set of nix package definitions
based on the contents of a mix.lock file. It makes it a little easier to manage
Elixir dependencies with nix.

To understand where it fits in with other tools used to package Elixir libraries
and releases for Nix, please read the [Packaging BEAM Applications](https://nixos.org/manual/nixpkgs/stable/#packaging-beam-applications) section
of the Nixpkgs Manual.

## Usage

### Generate an expression set

Generate an expression set and save it to a file:
```
$ mix2nix > deps.nix
```

You can also specify a path to your mix.lock file:
```
$ mix2nix /path/to/mix.lock > deps.nix
```

### Using generated expressions in your project

You can import your generated package set into your own package definition like
any other function. An example default.nix could look something like:
```nix
{ pkgs ? import <nixpkgs> {} }:

with pkgs; with beamPackages;

let
  deps = import ./deps.nix { inherit lib beamPackages; };
in
buildMix rec {
  name = "example-package";
  src = ./.;
  version = "0.0.0";

  beamDeps = [
    deps.package1
    deps.package2
  ];
}
```

If you are packaging your application as a release:
```nix
{ pkgs ? import <nixpkgs> {} }:

with pkgs; with beamPackages;

mixRelease {
  pname = "example-release";
  src = ./.;
  version = "0.0.0";

  mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
}
```

### Overriding package definitions

You can override any package by passing in an `overrides` attribute:
```nix
let
  deps = import ./deps.nix { inherit lib beamPackages; overrides = overrideDeps; };

  overrideDeps = (self: super: {
    package1 = super.package1.override {
      enableDebugInfo = true;
      compilePorts = true;
    };
  };
in
...
```

### Dependencies from outside of Hex.pm Repository

Currently, only public packages from Hex.pm are supported. If you have any
dependencies from git, private repositories, or local sources, you will need
to manually specify those.

## Build and Install

To create a development environment:
```
$ nix develop
```

To build without adding to global environment:
```
$ nix build
```

To install in your environment:
```
$ nix profile install
```

## Changelog

### 0.2.0
* Update NixOS input to 24.05
* Remove package-specific workarounds that are no longer necessary. If using an earlier version of NixOS, you may need to stay on version 0.1.9 or mix2nix.
