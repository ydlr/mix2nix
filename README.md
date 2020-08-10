# Mix2nix
Generate a set of nix derivations from a mix.lock file.

## Usage
Generate a set of nix derivations and save to file:
```
$ mix2nix mix.lock > deps.nix
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

## Known issues and limitations
This is very much a work-in-progress. It works nicely within my narrow use-case
(phoenix app with few dependencies). Below are some known limitations:

* It only supports Hex.pm. It doesn't work with dependencies from git
repositories.
* The expression for some packages may not work as is. If you find a package
that results in an invalid expression, please let me know.