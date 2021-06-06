defmodule Mix2nixTest do
	use ExUnit.Case
	doctest Mix2nix

	test "return nix expression from a map of dependencies" do
		input = %{
  		decimal: {
				:hex,
				:decimal,
				"1.8.1",
				"a4ef3f5f3428bdbc0d35374029ffcf4ede8533536fa79896dd450168d9acdf3c",
				[:mix],
				[],
				"hexpm"
			},
  		ecto: {
				:hex,
				:ecto,
				"3.3.3",
				"0830bf3aebcbf3d8c1a1811cd581773b6866886c012f52c0f027031fa96a0b53",
				[:mix],
				[
					{:decimal, "~> 1.6 or ~> 2.0", [hex: :decimal, repo: "hexpm", optional: false]},
					{:jason, "~> 1.0", [hex: :jason, repo: "hexpm", optional: true]},
					{:fake, "~> 2.0", [hex: :fake, repo: "hexpm", optional: true]}
				],
				"hexpm"
			},
  		jason: {
				:hex,
				:jason,
				"1.1.2",
				"b03dedea67a99223a2eaf9f1264ce37154564de899fd3d8b9a21b1a6fd64afe7",
				[:mix],
				[
					{:decimal, "~> 1.0", [hex: :decimal, repo: "hexpm", optional: true]}
				],
				"hexpm",
				"b03dedea67a99223a2eaf9f1264ce37154564de899fd3d8b9a21b1a6fd64gfe7"
			},
			scrivener_html: {
				:git,
				"https://github.com/jerodsanto/scrivener_html.git",
				"3e233754e559e6c3c665b373ea1c0d853a66d37a",
				[ref: "3e233754e559e6c3c665b373ea1c0d853a66d37a"]
			},
			cowboy: {
				:hex,
				:cowboy,
				"2.8.0",
				"f3dc62e35797ecd9ac1b50db74611193c29815401e53bac9a5c0577bd7bc667d",
				[:rebar3],
				[
					{:cowlib, "~> 2.9.1", [hex: :cowlib, repo: "hexpm", optional: false]},
					{:ranch, "~> 1.7.1", [hex: :ranch, repo: "hexpm", optional: false]}
				],
				"hexpm",
				"4643e4fba74ac96d4d152c75803de6fad0b3fa5df354c71afdd6cbeeb15fac8a"
			}
		}

		expected = """
		           { lib, beamPackages, overrides ? (x: y: {}) }:

		           let
		           	buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
		           	buildMix = lib.makeOverridable beamPackages.buildMix;
		           	buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

		           	self = packages // (overrides self packages);

		           	packages = with beamPackages; with self; {
		           		cowboy = buildErlangMk rec {
		           			name = "cowboy";
		           			version = "2.8.0";

		           			src = fetchHex {
		           				pkg = "${name}";
		           				version = "${version}";
		           				sha256 = "12mcbyqyxjynzldcfm7kbpxb7l7swqyq0x9c2m6nvjaalzxy8hs6";
		           			};

		           			beamDeps = [ cowlib ranch ];
		           		};

		           		decimal = buildMix rec {
		           			name = "decimal";
		           			version = "1.8.1";

		           			src = fetchHex {
		           				pkg = "${name}";
		           				version = "${version}";
		           				sha256 = "1v3srbdrvb9yj9lv6ljig9spq0k0g55wqjmxdiznib150aq59c9w";
		           			};

		           			beamDeps = [];
		           		};

		           		ecto = buildMix rec {
		           			name = "ecto";
		           			version = "3.3.3";

		           			src = fetchHex {
		           				pkg = "${name}";
		           				version = "${version}";
		           				sha256 = "0fiwp7cdy08yxhh63mnqqh7r10hfwkdapynyfrvqv4x2qbiniqqj";
		           			};

		           			beamDeps = [ decimal jason ];
		           		};

		           		jason = buildMix rec {
		           			name = "jason";
		           			version = "1.1.2";

		           			src = fetchHex {
		           				pkg = "${name}";
		           				version = "${version}";
		           				sha256 = "1zispkj3s923izkwkj2xvaxicd7m0vi2xnhnvvhkl82qm2y47y7x";
		           			};

		           			beamDeps = [ decimal ];
		           		};
		           	};
		           in self
		           """
		assert expected == Mix2nix.expression_set(input)
	end
end
