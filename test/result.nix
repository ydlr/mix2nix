{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    acceptor_pool = buildRebar3 rec {
      name = "acceptor_pool";
      version = "1.0.0";

      src = fetchHex {
        pkg = "acceptor_pool";
        version = "${version}";
        sha256 = "0cbcd83fdc8b9ad2eee2067ef8b91a14858a5883cb7cd800e6fcd5803e158788";
      };

      beamDeps = [];
    };

    chatterbox = buildRebar3 rec {
      name = "chatterbox";
      version = "0.13.0";

      src = fetchHex {
        pkg = "ts_chatterbox";
        version = "${version}";
        sha256 = "b93d19104d86af0b3f2566c4cba2a57d2e06d103728246ba1ac6c3c0ff010aa7";
      };

      beamDeps = [ hpack ];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.9.0";

      src = fetchHex {
        pkg = "cowboy";
        version = "${version}";
        sha256 = "2c729f934b4e1aa149aff882f57c6372c15399a20d54f65c8d67bef583021bde";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.11.0";

      src = fetchHex {
        pkg = "cowlib";
        version = "${version}";
        sha256 = "2b3e9da0b21c4565751a6d4901c20d1b4cc25cbb7fd50d91d2ab6dd287bc86a9";
      };

      beamDeps = [];
    };

    ctx = buildRebar3 rec {
      name = "ctx";
      version = "0.6.0";

      src = fetchHex {
        pkg = "ctx";
        version = "${version}";
        sha256 = "a14ed2d1b67723dbebbe423b28d7615eb0bdcba6ff28f2d1f1b0a7e1d4aa5fc2";
      };

      beamDeps = [];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.0.0";

      src = fetchHex {
        pkg = "decimal";
        version = "${version}";
        sha256 = "34666e9c55dea81013e77d9d87370fe6cb6291d1ef32f46a1600230b1d44f577";
      };

      beamDeps = [];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.9.4";

      src = fetchHex {
        pkg = "ecto";
        version = "${version}";
        sha256 = "de5f988c142a3aa4ec18b85a4ec34a2390b65b24f02385c1144252ff6ff8ee75";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    gproc = buildRebar3 rec {
      name = "gproc";
      version = "0.8.0";

      src = fetchHex {
        pkg = "gproc";
        version = "${version}";
        sha256 = "580adafa56463b75263ef5a5df4c86af321f68694e7786cb057fd805d1e2a7de";
      };

      beamDeps = [];
    };

    grpcbox = buildRebar3 rec {
      name = "grpcbox";
      version = "0.16.0";

      src = fetchHex {
        pkg = "grpcbox";
        version = "${version}";
        sha256 = "294df743ae20a7e030889f00644001370a4f7ce0121f3bbdaf13cf3169c62913";
      };

      beamDeps = [ acceptor_pool chatterbox ctx gproc ];

      unpackPhase = ''
        runHook preUnpack
        unpackFile "$src"
        chmod -R u+w -- hex-source-grpcbox-0.16.0
        mv hex-source-grpcbox-0.16.0 grpcbox
        sourceRoot=grpcbox
        runHook postUnpack
      '';
    };

    hpack = buildRebar3 rec {
      name = "hpack";
      version = "0.2.3";

      src = fetchHex {
        pkg = "hpack_erl";
        version = "${version}";
        sha256 = "06f580167c4b8b8a6429040df36cc93bba6d571faeaec1b28816523379cbb23a";
      };

      beamDeps = [];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.0";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "79a3791085b2a0f743ca04cec0f7be26443738779d09302e01318f97bdb82121";
      };

      beamDeps = [ decimal ];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "ranch";
        version = "${version}";
        sha256 = "49fbcfd3682fab1f5d109351b61257676da1a2fdbe295904176d5e521a2ddfe5";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "dad9ce9d8effc621708f99eac538ef1cbe05d6a874dd741de2e689c47feafed5";
      };

      beamDeps = [];
    };
  };
in self
