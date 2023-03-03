{ lib,
  beamPackages,
  overrides ? (x: y: {}),
  #
  # NOTE : for private hex org pkgs only
  #
  stdenv ? null,
  stdenvNoCC ? null,
  mix2nix ? null,
  hexOrg ? null,
  hexKey ? null
}:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  fetchHexOrg = ({
    pkg
    , version
    , sha256
    , meta ? { }
    , hexOrg
    , hexKey
    }:

    let fetchHexCore =
      stdenvNoCC.mkDerivation (rec {
        name = "${pkg}-${version}.tar";
        buildCommand = ''
          ${mix2nix}/bin/mix2nix \
            --hex-pkg-get ${pkg} \
            --hex-pkg-vsn ${version} \
            --hex-pkg-org ${hexOrg} \
            --hex-api-key ${hexKey}
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
    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2c729f934b4e1aa149aff882f57c6372c15399a20d54f65c8d67bef583021bde";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.11.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "2b3e9da0b21c4565751a6d4901c20d1b4cc25cbb7fd50d91d2ab6dd287bc86a9";
      };

      beamDeps = [];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "34666e9c55dea81013e77d9d87370fe6cb6291d1ef32f46a1600230b1d44f577";
      };

      beamDeps = [];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.9.4";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "de5f988c142a3aa4ec18b85a4ec34a2390b65b24f02385c1144252ff6ff8ee75";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "79a3791085b2a0f743ca04cec0f7be26443738779d09302e01318f97bdb82121";
      };

      beamDeps = [ decimal ];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1rfz5ld54pkd2w25jadyznia2vb7aw9bclck21fizargd39wzys9";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "dad9ce9d8effc621708f99eac538ef1cbe05d6a874dd741de2e689c47feafed5";
      };

      beamDeps = [];
    };
  };
in self
