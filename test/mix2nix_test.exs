defmodule Mix2nixTest do
  use ExUnit.Case
  doctest Mix2nix

  test "return nix expression from a map of dependencies" do
    assert File.read!("./test/result.nix") == Mix2nix.process("./test/mix.lock")
  end


  test "get_hexpm_expression with environment variables" do
    allpkgs = %{
      cc_precompiler: %{required: true},
      db_connection: %{required: true},
      elixir_make: %{required: true}
    }

    name = :exqlite
    hex_name = :exqlite
    version = "0.29.0"
    builders = [:mix]
    deps = [
      {:cc_precompiler, "0.1.0", [hex: :cc_precompiler, repo: "hexpm", optional: false]},
      {:db_connection, "2.4.0", [hex: :db_connection, repo: "hexpm", optional: false]},
      {:elixir_make, "0.6.0", [hex: :elixir_make, repo: "hexpm", optional: false]}
    ]

    env_vars = %{"ELIXIR_MAKE_CACHE_DIR" => "$TMPDIR/.cache"}
    sha256 = "a75f8a069fcdad3e5f95dfaddccd13c2112ea3b742fdcc234b96410e9c1bde00"

    result = Mix2nix.get_hexpm_expression(allpkgs, name, hex_name, version, builders, deps, env_vars, sha256)

    expected = """
        exqlite = buildMix rec {
          name = "exqlite";
          version = "0.29.0";

          src = fetchHex {
            pkg = "exqlite";
            version = "${version}";
            sha256 = "a75f8a069fcdad3e5f95dfaddccd13c2112ea3b742fdcc234b96410e9c1bde00";
          };

          preBuild = ''
            export ELIXIR_MAKE_CACHE_DIR="$TMPDIR/.cache"
          '';

          beamDeps = [ cc_precompiler db_connection elixir_make ];
        };
    """

    assert String.trim(result) == String.trim(expected)
  end

  test "get_hexpm_expression without environment variables" do
    allpkgs = %{
      cc_precompiler: %{required: true},
      db_connection: %{required: true},
      elixir_make: %{required: true}
    }

    name = :exqlite
    hex_name = :exqlite
    version = "0.29.0"
    builders = [:mix]
    deps = [
      {:cc_precompiler, "0.1.0", [hex: :cc_precompiler, repo: "hexpm", optional: false]},
      {:db_connection, "2.4.0", [hex: :db_connection, repo: "hexpm", optional: false]},
      {:elixir_make, "0.6.0", [hex: :elixir_make, repo: "hexpm", optional: false]}
    ]

    env_vars = %{}
    sha256 = "a75f8a069fcdad3e5f95dfaddccd13c2112ea3b742fdcc234b96410e9c1bde00"

    # Execute the function
    result = Mix2nix.get_hexpm_expression(allpkgs, name, hex_name, version, builders, deps, env_vars, sha256)

    # Define the expected output (without preBuild)
    expected = """
        exqlite = buildMix rec {
          name = "exqlite";
          version = "0.29.0";

          src = fetchHex {
            pkg = "exqlite";
            version = "${version}";
            sha256 = "a75f8a069fcdad3e5f95dfaddccd13c2112ea3b742fdcc234b96410e9c1bde00";
          };

          beamDeps = [ cc_precompiler db_connection elixir_make ];
        };
    """

    # Assert the result matches the expected output
    assert String.trim(result) == String.trim(expected)
  end
end
