defmodule Mix2nix do
  alias Mix2nix.Env

  def hex_pkg_get(%Env{pkg: pkg, vsn: vsn, org: org, prv: prv, pub: pub, url: url} = env) do
    IO.puts("Tarball fetch with " <> inspect(env))

    org_key =
      if url do
        :repo_name
      else
        :repo_organization
      end

    :hex_core.default_config()
    |> Map.update!(:http_adapter, fn _ -> {Mix2nix.Hackney, %{}} end)
    |> Map.update!(org_key, &((org && org) || &1))
    |> Map.update!(:repo_key, &((prv && Env.unshield(prv)) || &1))
    |> Map.update!(:repo_public_key, &((pub && pub) || &1))
    |> Map.update!(:repo_url, &((url && url) || &1))
    |> :hex_repo.get_tarball(pkg, vsn)
    |> case do
      {:ok, {200, %{}, tar}} ->
        IO.puts("Tarball fetch success!")
        tar

      failure ->
        IO.puts("Tarball fetch failure " <> inspect(failure))
        System.halt(1)
    end
  end

  def process(filename) do
    filename
    |> read
    |> expression_set
  end

  def expression_set(deps) do
    deps
    |> Map.to_list()
    |> Enum.sort(:asc)
    |> Enum.map(fn {name_str, v} -> nix_expression(deps, name_str, v) end)
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
    #
    # TODO : !!!
    #
    tar =
      hex_pkg_get(%Env{
        pkg: name,
        vsn: version,
        org: nil,
        prv: nil,
        pub: nil,
        url: nil
      })

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
        _,
        {:hex, name, version, _hash, builders, deps, <<"hexpm", org::binary>>, hash2}
      ) do
    get_hexpm_expression(
      allpkgs,
      %Env{
        pkg: Atom.to_string(name),
        vsn: version,
        org: parse_org(org),
        prv: nil,
        pub: nil,
        url: nil
      },
      builders,
      deps,
      hash2
    )
  end

  def nix_expression(
        allpkgs,
        _,
        {:hex, name, version, _hash, builders, deps, <<"hexpm", org::binary>>}
      ) do
    get_hexpm_expression(
      allpkgs,
      %Env{
        pkg: Atom.to_string(name),
        vsn: version,
        org: parse_org(org),
        prv: nil,
        pub: nil,
        url: nil
      },
      builders,
      deps
    )
  end

  def nix_expression(
        allpkgs,
        _,
        {:hex, name, version, _hash, builders, deps, nonhex, hash2}
      ) do
    get_hexpm_expression(
      allpkgs,
      %Env{
        pkg: Atom.to_string(name),
        vsn: version,
        org: nonhex,
        prv: nil,
        pub: nil,
        url: nil
      },
      builders,
      deps,
      hash2
    )
  end

  def nix_expression(
        allpkgs,
        _,
        {:hex, name, version, _hash, builders, deps, nonhex}
      ) do
    get_hexpm_expression(
      allpkgs,
      #
      # TODO : propagate creds for nonhex tar fetch
      #
      %Env{
        pkg: Atom.to_string(name),
        vsn: version,
        org: nonhex,
        prv: nil,
        pub: nil,
        url: nil
      },
      builders,
      deps
    )
  end

  def nix_expression(_allpkgs, name_str, {:git, url, rev, opts}) do
    ref =
      case opts[:branch] do
        nil -> ""
        ref -> "ref = \"#{ref}\";"
      end

    """
        #{name_str} = buildMix rec {
          name = "#{name_str}";
          src = fetchGitMixDep {
            name = "${name}";
            url = "#{url}";
            rev = "#{rev}";
            #{ref}
          };
          version = builtins.readFile src.version;
          # Interection of all of the packages mix2nix found and those
          # declared in the package:
          beamDeps = with builtins; map (a: getAttr a packages) (filter (a: hasAttr a packages) (lib.splitString " " (readFile src.deps)));
        };
    """
  end

  def nix_expression(_allpkgs, _, _pkg) do
    ""
  end

  defp parse_org(<<":", org::binary>>), do: org
  defp parse_org(<<>>), do: nil

  defp get_hexpm_expression(allpkgs, env, builders, deps, sha256 \\ nil) do
    %Env{pkg: name, vsn: version, org: org} = env
    buildEnv = get_build_env(builders, name)
    sha256 = sha256 || get_hash(name, version)
    deps = dep_string(allpkgs, deps)

    src =
      if org do
        """
        src = fetchHexOrg {
                pkg = "${name}";
                version = "${version}";
                sha256 = "#{sha256}";
                inherit hexOrg hexPrv;
              };
        """
      else
        """
        src = fetchHex {
                pkg = "${name}";
                version = "${version}";
                sha256 = "#{sha256}";
              };
        """
      end

    """
        #{name} = #{buildEnv} rec {
          name = "#{name}";
          version = "#{version}";

          #{src}
          beamDeps = #{deps};
        };
    """
  end

  defp wrap(pkgs) do
    """
    { lib,
      beamPackages,
      overrides ? (x: y: {}),
      #
      # NOTE : for private hex org and git pkgs only
      #
      stdenv ? null,
      stdenvNoCC ? null,
      mix2nix ? null,
      hexOrg ? null,
      hexPrv ? null,
      hexPub ? null,
      hexUrl ? null
    }:

    let
      buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
      buildMix = lib.makeOverridable beamPackages.buildMix;
      buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

      fetchGitMixDep = attrs@{ name, url, rev, ref ? null }: stdenv.mkDerivation {
        inherit name;
        src = builtins.fetchGit attrs;
        nativeBuildInputs = [ beamPackages.elixir ];
        outputs = [ "out" "version" "deps" ];
        # Create a fake .git folder that will be acceptable to Mix's SCM lock check:
        # https://github.com/elixir-lang/elixir/blob/74bfab8ee271e53d24cb0012b5db1e2a931e0470/lib/mix/lib/mix/scm/git.ex#L242
        buildPhase = ''
            mkdir -p .git/objects .git/refs
            echo ${rev} > .git/HEAD
            echo '[remote "origin"]' > .git/config
            echo "    url = ${url}" >> .git/config
        '';
        installPhase = ''
            # The main package
            cp -r . $out
            # Metadata: version
            echo "File.write!(\\"$version\\", Mix.Project.config()[:version])" | iex -S mix cmd true
            # Metadata: deps as a newline separated string
            echo "File.write!(\\"$deps\\", Mix.Project.config()[:deps] |> Enum.map(& &1 |> elem(0) |> Atom.to_string()) |> Enum.join(\\" \\"))" | iex -S mix cmd true
        '';
      };

      fetchHexOrg = (#{fetch_hex_org()}  );

      self = packages // (overrides self packages);

      packages = with beamPackages; with self; {
    #{pkgs}
      };
    in self
    """
  end

  defp fetch_hex_org do
    """
    {
        pkg
        , version
        , sha256
        , meta ? { }
        , hexOrg
        , hexPrv
        , hexPub ? null
        , hexUrl ? null
        }:

        let
          hexPubStr =
            if hexPub == null
            then ""
            else "--hex-key-pub ${hexPub}";
          hexUrlStr =
            if hexUrl == null
            then ""
            else "--hex-srv-url ${hexUrl}";
          fetchHexCore =
            stdenvNoCC.mkDerivation (rec {
              name = "${pkg}-${version}.tar";
              buildCommand = ''
                ${mix2nix}/bin/mix2nix \\
                  --hex-pkg-get ${pkg} \\
                  --hex-pkg-vsn ${version} \\
                  --hex-pkg-org ${hexOrg} \\
                  --hex-key-prv ${hexPrv} ${hexPubStr} ${hexUrlStr}
                mv ${name} $out
              '';
              outputHashAlgo = "sha256";
              outputHash = sha256;
            });

        in
          stdenv.mkDerivation ({
            pname = "hex-source-${pkg}";
            inherit version;
            dontBuild = true;
            dontConfigure = true;
            dontFixup = true;

            src = fetchHexCore;

            unpackCmd = ''
              tar -xf $curSrc contents.tar.gz CHECKSUM metadata.config
              mkdir contents
              tar -C contents -xzf contents.tar.gz
              mv metadata.config contents/hex_metadata.config

              # To make the extracted hex tarballs appear legitimate to mix, we need to
              # make sure they contain not just the contents of contents.tar.gz but also
              # a .hex file with some lock metadata.
              # We use an old version of .hex file per hex's mix_task_test.exs since it
              # is just plain-text instead of an encoded format.
              # See: https://github.com/hexpm/hex/blob/main/test/hex/mix_task_test.exs#L410
              echo -n "${pkg},${version},$(cat CHECKSUM | tr '[:upper:]' '[:lower:]'),hexpm" > contents/.hex
            '';

            installPhase = ''
              runHook preInstall
              mkdir "$out"
              cp -Hrt "$out" .
              success=1
              runHook postInstall
            '';

            inherit meta;
          })
    """
  end
end
