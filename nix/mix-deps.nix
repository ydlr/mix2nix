{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    hex_core = buildRebar3 rec {
      name = "hex_core";
      version = "0.9.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "1wf2dh1icf7icja68x4ahw4x2pprr2l18f27vgghh6ji925l2q7i";
      };

      beamDeps = [];
    };

    temp = buildMix rec {
      name = "temp";
      version = "0.4.7";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "039ys0yccxnydgq8c9c8j0diwamfs5s1a0p1id3jg945d9yrxwba";
      };

      beamDeps = [];
    };
  };
in self

