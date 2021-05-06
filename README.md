# Mix2nix
Generate a set of nix derivations from a mix.lock file.

## Overview

The purpose of mix2nix is simply to create a set of nix package definitions
based on the contents of a mix.lock file. It is not an attempt at an
all-encompassing solution to distributing Elixir applications with Nix. As such,
the scope will always be limited to generating nix configurations based on
information available in mix.lock.

The dream is for a dead-simple, completely accurate method of packaging
Elixir (and other BEAM) packages for Nix without sacrificing reproducability.
Mix2nix, though, is only meant to tackle one small piece of the puzzle.

## Usage

### Generate an expession set

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
any other function. As example default.nix could look something like:
```
{ pkgs ? import <nixpkgs> {} }:

with pkgs; with beamPackages;

let
  deps = import ./deps.nix { inherit lib beamPackages; };
in
buildMix rec {
  name = "example-package";
  src = ./.;

  beamDeps = [
    deps.package1
    deps.package2
  ];
}
```

### Overriding package definitions

You can override any package by passing in an `overrides` attribute:
```
let
  deps = import ./deps.nix { inherit lib beamPackages; overrides = overrideDeps; };

  overrideDeps = {
    package1 = deps.package1.override {
      enableDebugInfo = true;
      compilePorts = true;
    };
  };
in
...
```

### Rebar3 Plugins

If you require any rebar packages that use plugins, mix2nix generated package
definitions will not be aware of these. This is because neither mix.lock nor
reback.lock are plugin-aware.

In order to declare those plugins, you will need to:
1. Add these plugins as dependencies in your mix.exs file.
2. Run mix2nix to generate your package set.
3. Override the packages that need to be made aware of their plugins.

For example, telemetry requires covertool plugin. An override would look
like:
```
overrides = {
  telemetry = deps.telemetry.override {
    buildPlugins = [ covertool ];
  };
}
```

### Dependencies from outside of Hex.pm Repository

Currently, only public packages from Hex.pm are supported. If you have any
dependencies from git, private repositories, or local sources, you will need
to manually specify those.

## Build and Install

To create a development environment:
```
$ nix-shell
```

To build without adding to global environment:
```
$ nix-build
```

To install in your environment:
```
$ nix-env -f ./ -i
```
