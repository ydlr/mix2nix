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
* Support private Hex.pm packages
* Support alternative Hex repositories

## Known issues and limitations
This is very much a work-in-progress. It works nicely within my narrow use-case
(phoenix app with few dependencies). Right now, it only supports public packages
from the Hex.pm repository. The expression for some package may not work as is.
If you find a package that results in an invalid expresion, please let me know.
