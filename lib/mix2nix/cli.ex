defmodule Mix2nix.CLI do
	def main(args \\ []) do
		case lock_file_from_args(args) do
			{:error, e} ->
				IO.puts( expected_input() <> "\n")
				raise "Error parsing commandline arguments: #{e}"
			{:ok, lock} ->
				lock
				|> Mix2nix.process
				|> IO.puts()
		end
	end

	def lock_file_from_args([lock]) do
		case File.exists?(lock) do
			true ->
				{:ok, lock}
			false ->
				{:error, "Lock file #{lock} not found."}
		end
	end

	def lock_file_from_args([_lock | _tail]) do
		{:error, "Extra arguments not supported."}
	end

	def lock_file_from_args([]) do
		case File.exists?("mix.lock") do
			true ->
				{:ok, "mix.lock"}
			false ->
				{:error, "Unable to find mix.lock file in current directory."}
		end
	end

	def expected_input() do
		"Usage: mix2nix [filename]"
	end
end
