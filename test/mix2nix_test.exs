defmodule Mix2nixTest do
  use ExUnit.Case
  doctest Mix2nix

  test "return nix expression from a map of dependencies" do
    assert File.read!("./test/result.nix") == Mix2nix.process("./test/mix.lock")
  end
end
