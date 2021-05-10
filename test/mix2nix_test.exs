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
  		"jason": {
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
			"scrivener_html": {
				:git,
				"https://github.com/jerodsanto/scrivener_html.git",
				"3e233754e559e6c3c665b373ea1c0d853a66d37a",
				[ref: "3e233754e559e6c3c665b373ea1c0d853a66d37a"]
			}
		}

		expected = """
		           { lib, beamPackages, overrides ? {} }:

		           let
		           	buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
		           	buildMix = lib.makeOverridable beamPackages.buildMix;
		           	buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

		           	self = packages // (overrides self packages);

		           	packages = with beamPackages; with self; {
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
