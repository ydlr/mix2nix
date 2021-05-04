# Mix2nix
Generate a set of nix derivations from a mix.lock file.

## Usage
By default, mix2nix looks expects a mix.lock file in the current working
directory and outputs to STDOUT. You can optionally specify a path to the
lockfile and a destination for the output:
```
$ mix2nix > deps.nix
$ mix2nix /path/to/mix.lock > deps.nix
```

You can then import the packages into your nix configuration:
```
deps = import ./deps { inherit pkgs; };
```

Packages can then be referred to as `deps.<package-name>`.


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

## Roadmap

* Support git sources
* Support local sources
* Support private Hex.pm packages
* Support alternative Hex repositories
* Allow specifying which version of Erlang/OTP to build pacakges against.

## Not on the Roadmap

The scope of this project is extremely limited: To consume a mix.lock file and
return a set of expressions for building and installing the listed packages with
the Nix package manager.

This is NOT intended to be an all-powerful single command to package your Elixir
application for Nix.

## Known issues and limitations
This is very much a work-in-progress. It works nicely within my narrow use-case
(phoenix app with few dependencies). Right now, it only supports public packages
from the Hex.pm repository. The expression for some package may not work as is.
If you find a package that does not build or execute from the generated
expression, please let me know.

Currently, any git or local dependencies will simply be skipped without a
warning.
