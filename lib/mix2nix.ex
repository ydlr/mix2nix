defmodule Mix2nix do
  def process(filename, env_vars \\ %{}) do
    filename
    |> read
    |> expression_set(env_vars)
  end

  def expression_set(deps, env_vars) do
    deps
    |> Map.to_list()
    |> Enum.sort(:asc)
    |> Enum.map(fn {k, v} -> nix_expression(deps, k, v, env_vars) end)
    |> Enum.reject(fn x -> x == "" end)
    |> Enum.join("\n")
    |> String.trim("\n")
    |> wrap
  end

  defp read(filename) do
    opts = [
      emit_warnings: false,
      file: filename
    ]

    with {:ok, contents} <- File.read(filename),
         {:ok, quoted} <- Code.string_to_quoted(contents, opts),
         {%{} = lock, _} <- Code.eval_quoted(quoted, opts) do
      lock
    else
      {:error, posix} when is_atom(posix) ->
        :file.format_error(posix) |> to_string() |> IO.puts()
        System.halt(1)

      {:error, {line, error, token}} when is_integer(line) ->
        IO.puts("Error on line #{line}: #{error} (" <> inspect(token) <> ")")
        System.halt(1)
    end
  end

  def is_required(allpkgs, hex: name, repo: _, optional: optional) do
    Map.has_key?(allpkgs, name) or !optional
  end

  def dep_string(allpkgs, deps) do
    depString =
      deps
      |> Enum.filter(fn x -> is_required(allpkgs, elem(x, 2)) end)
      |> Enum.map(fn x -> Atom.to_string(elem(x, 0)) end)
      |> Enum.join(" ")

    if String.length(depString) > 0 do
      "[ " <> depString <> " ]"
    else
      "[]"
    end
  end

  def specific_workaround(pkg) do
    case pkg do
      "cowboy" -> "buildErlangMk"
      "ssl_verify_fun" -> "buildRebar3"
      "jose" -> "buildMix"
      _ -> false
    end
  end

  def get_build_env(builders, pkgname) do
    cond do
      specific_workaround(pkgname) ->
        specific_workaround(pkgname)

      Enum.member?(builders, :mix) ->
        "buildMix"

      Enum.member?(builders, :rebar3) or Enum.member?(builders, :rebar) ->
        "buildRebar3"

      Enum.member?(builders, :make) ->
        "buildErlangMk"

      true ->
        "buildMix"
    end
  end

  def get_hash(name, version) do
    url = "https://repo.hex.pm/tarballs/#{name}-#{version}.tar"
    {result, status} = System.cmd("nix-prefetch-url", [url])

    case status do
      0 ->
        String.trim(result)

      _ ->
        IO.puts("Use of nix-prefetch-url failed.")
        System.halt(1)
    end
  end

  defp generate_pre_build(env_vars) when is_nil(env_vars) or env_vars == %{} do
    ""
  end

  defp generate_pre_build(env_vars) when is_map(env_vars) do
  env_exports = env_vars
    |> Enum.map(fn {key, value} ->
      quoted_value = if String.contains?(value, [" ", "$", "\"", "'", ";"]) do
        "\"#{value}\""
      else
        value
      end
      "        export #{key}=#{quoted_value}"
    end)
    |> Enum.join("\n")

  """

        preBuild = ''
#{env_exports}
        '';
  """
  end

  def nix_expression(
    allpkgs,
    name,
    {:hex, hex_name, version, _hash, builders, deps, "hexpm", hash2},
    env_vars
  ),
    do: get_hexpm_expression(allpkgs, name, hex_name, version, builders, deps, env_vars, hash2)

  def nix_expression(
    allpkgs,
    name,
    {:hex, hex_name, version, _hash, builders, deps, "hexpm"},
    env_vars
  ),
    do: get_hexpm_expression(allpkgs, name, hex_name, version, builders, deps, env_vars)

  def nix_expression(_allpkgs, _name, _pkg, _env_vars) do
    ""
  end

  def get_hexpm_expression(allpkgs, name, hex_name, version, builders, deps, env_vars, sha256 \\ nil) do
    name = Atom.to_string(name)
    hex_name = Atom.to_string(hex_name)
    buildEnv = get_build_env(builders, name)
    sha256 = sha256 || get_hash(hex_name, version)
    deps = dep_string(allpkgs, deps)

    pre_build = generate_pre_build(env_vars)

    """
        #{name} = #{buildEnv} rec {
          name = "#{name}";
          version = "#{version}";

          src = fetchHex {
            pkg = "#{hex_name}";
            version = "${version}";
            sha256 = "#{sha256}";
          };
    #{pre_build}
          beamDeps = #{deps};
        };
    """
  end

  defp wrap(pkgs) do
    """
    { lib, beamPackages, overrides ? (x: y: {}) }:

    let
      buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
      buildMix = lib.makeOverridable beamPackages.buildMix;
      buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

      self = packages // (overrides self packages);

      packages = with beamPackages; with self; {
    #{pkgs}
      };
    in self
    """
  end
end
