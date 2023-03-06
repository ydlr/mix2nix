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
        echo "File.write!(\"$version\", Mix.Project.config()[:version])" | iex -S mix cmd true
        # Metadata: deps as a newline separated string
        echo "File.write!(\"$deps\", Mix.Project.config()[:deps] |> Enum.map(& &1 |> elem(0) |> Atom.to_string()) |> Enum.join(\" \"))" | iex -S mix cmd true
    '';
  };

  fetchHexOrg = ({
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
            ${mix2nix}/bin/mix2nix \
              --hex-pkg-get ${pkg} \
              --hex-pkg-vsn ${version} \
              --hex-pkg-org ${hexOrg} \
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
  );

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "266da46bdb06d6c6d35fde799bcb28d36d985d424ad7c08b5bb48f5b5cdd4641";
      };

      beamDeps = [];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.18.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "a4ecdaff44297e9b5894ae499e9a070ea1888c84afdd1fd9b7b2bc384950128e";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    hex_core = buildRebar3 rec {
      name = "hex_core";
      version = "0.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f160418b48511a08dfdb473814a8c8f95ed109878a74649464f13816036cc2f1";
      };

      beamDeps = [];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.2.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "f278585650aa581986264638ebf698f8bb19df297f66ad91b18910dfc6e19323";
      };

      beamDeps = [];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.3.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "07cd9577885f56362d414e8c4c4e6bdf10d43a8767abb92d24cbe8b24c54888b";
      };

      beamDeps = [];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.6";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "bdb0d2471f453c88ff3908e7686f86f9be327d065cc1ec16fa4540197ea04680";
      };

      beamDeps = [];
    };

    temp = buildMix rec {
      name = "temp";
      version = "0.4.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "6af19e7d6a85a427478be1021574d1ae2a1e1b90882586f06bde76c63cd03e0d";
      };

      beamDeps = [];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [];
    };
  };
in self

