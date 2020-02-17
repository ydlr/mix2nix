defmodule Mix2nixTest do
	use ExUnit.Case
	doctest Mix2nix

	test "returns true when dependency is not optional" do
		assert true == Mix2nix.is_required([hex: :cowlib, repo: "hexpm", optional: false])
	end

	test "returns false when dependency is optional" do
		assert false ==  Mix2nix.is_required([hex: :cowlib, repo: "hexpm", optional: true])
	end

	test "returns a string representation of dependencies" do
		deps = [
			{:cowlib, "~> 2.7.3", [hex: :cowlib, repo: "hexpm", optional: false]},
			{:ranch, "~> 1.7.1", [hex: :ranch, repo: "hexpm", optional: false]},
			{:file_system, "~> 0.2.1 or ~> 0.3", [hex: :file_system, repo: "hexpm", optional: true]},
		]

		assert "[ cowlib ranch ]" == Mix2nix.dep_string(deps)
	end

	test "return a string representation of an empty list" do
		assert "[]" == Mix2nix.dep_string([])
	end
end
