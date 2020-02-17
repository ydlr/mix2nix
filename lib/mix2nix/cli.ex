defmodule Mix2nix.CLI do
	def main(args \\ []) do
		args
		|> hd
		|> Mix2nix.process
		|> IO.puts()
	end
end