defmodule Mix2nix do
  def process(filename) do
    filename
    |> read
    |> expression_set
  end

  def expression_set(deps) do
    deps
    |> Map.to_list()
    |> Enum.sort(:asc)
    |> Enum.map(fn {_, v} -> nix_expression(deps, v) end)
    |> Enum.reject(fn x -> x == "" end)
    |> Enum.join("\n")
    |> String.trim("\n")
    |> wrap
  end

  defp read(filename) do
    opts = [file: filename, warn_on_unnecessary_quotes: false]

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
    {200, %{}, tar} = :hex_client.get_repo_tarball(name, version)
    Temp.track!()
    {:ok, _, tmp} = Temp.open()
    :ok = File.write!(tmp, tar)
    {result, status} = System.cmd("nix-prefetch-url", ["file://" <> tmp])
    Temp.cleanup()

    case status do
      0 ->
        String.trim(result)

      _ ->
        IO.puts("Use of nix-prefetch-url failed.")
        System.halt(1)
    end
  end

  def nix_expression(
        allpkgs,
        {:hex, name, version, _hash, builders, deps, <<"hexpm", _::binary>>, hash2}
      ),
      do: get_hexpm_expression(allpkgs, name, version, builders, deps, hash2)

  def nix_expression(
        allpkgs,
        {:hex, name, version, _hash, builders, deps, <<"hexpm", _::binary>>}
      ),
      do: get_hexpm_expression(allpkgs, name, version, builders, deps)

  def nix_expression(_allpkgs, _pkg) do
    ""
  end

  defp get_hexpm_expression(allpkgs, name, version, builders, deps, sha256 \\ nil) do
    name = Atom.to_string(name)
    buildEnv = get_build_env(builders, name)
    sha256 = sha256 || get_hash(name, version)
    deps = dep_string(allpkgs, deps)

    """
        #{name} = #{buildEnv} rec {
          name = "#{name}";
          version = "#{version}";

          src = fetchHex {
            pkg = "${name}";
            version = "${version}";
            sha256 = "#{sha256}";
          };

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
