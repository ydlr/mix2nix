# Mix.lock File Format

This is a breakdown of the mix.lock format, as best as I can piece together from
situations I have encountered. I haven't been able to find any other
documentation on the format, but if it is out there, I'd love to know about it.

The top-level is a map where the package names are keys and the values are
tuples containing information about the package:

```
%{
  "package_name": { },
  "second_package": { }
}
```

The tuple representing a package hosted in Hex.pm will look like this:

```
{
  :hex,                  # declaring that it is a hex package

  :package,              # an atom matching the package name (key)

  "0.8.0",               # string representing the version

  "HASH",                # a hash of the package contents

  [:mix, :rebar3],       # a list of one or more build tools used by the package, as
                         # atoms. As far as I can tell, any one of the build tools
                         # listed should be sufficient to build the package.

  [                      # A list of dependencies as tuples

    {
      :package,          # an atom representing dependency

      "-> 1.9",          # a string representing a version range. mix2nix currently
                         # makes no attempt and ensuring this is satisfied. It just
                         # converts the top-level packages in mix.lock into nix
                         # expressions.

      [                  # A keyword list with package information

        hex: :package,   # An atom that matches the atom used in the top-level map
                         # to represent the package.

        repo: "hexpm",   # Repo that hosts the package source

        optional: false  # Whther the dependency is required. If it is, there
                         # should also be an entry for it in the top-level map.
                         # Whether there is a top-level entry or not, mix2nix
                         # will include this in `beamDeps` list in the generated
                         # nix expression for the parent package.
      ]
    }
  ],
  "hexpm",               # Possibly the repo where the found is found. I've
                         # always seen it as "hexpm", but it might be different
                         # if the package is hosted in a different Hex
                         # repository. mix2nix only supports public packages
                         # hosted on Hex.pm.

  "HASH"                 # Another package hash. Different from the first one.
}
```

The tuple representing packages with git sources is a little different:

```
{
  :git,                                     # declaring that it is a git package

  "https://git.imnotsoup.com/mix2nix",      # URL of git repo

  "HASH",                                   # A hash of package

  [branch: "branchname"]                    # a keyword list representing the
                                            # package version. Can be a branch
                                            # (:branch), tag (:tag), or commit
                                            # ref (:ref)
}
```
