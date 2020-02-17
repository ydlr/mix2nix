defmodule Mix2nix do
	def process(filename) do
		filename
		|> read
		|> Enum.map(fn {_, v} -> nix_expression(v) end)
		|> Enum.join("\n\n")
		|> wrap
	end

	defp read(filename) do
		opts = [file: filename, warn_on_unnecessary_quotes: false]

		with {:ok, contents} <- File.read(filename),
		     {:ok, quoted} <- Code.string_to_quoted(contents, opts),
		     {%{} = lock, _} <- Code.eval_quoted(quoted, opts) do
			lock
		else
			_ -> %{}
		end
	end

	def is_required([ _, _, optional: optional ]) do
		! optional
	end

	def dep_string(deps) do
		depString =
			deps
			|> Enum.filter(fn x -> is_required(elem(x, 2)) end)
			|> Enum.map(fn x -> Atom.to_string(elem(x, 0)) end)
			|> Enum.join(" ")

		if String.length(depString) > 0 do
			"[ " <> depString <> " ]"
		else
			"[]"
		end
	end

	def get_builder(env) do
		case env do
			:rebar3 -> "buildRebar3"
			:mix -> "buildMix"
		end
	end

	def get_hash(name, version) do
		url = "https://repo.hex.pm/tarballs/#{name}-#{version}.tar"
		{ result, status } = System.cmd("nix-prefetch-url", [url])

		case status do
			0 -> String.trim(result)
			_ -> raise "Use of nix-prefetch-url failed."
		end
	end

	def nix_expression(pkg) do
		with [buildEnv] <- elem(pkg, 4),
		     builder <- get_builder(buildEnv),
		     name <- Atom.to_string(elem(pkg, 1)),
		     version <- elem(pkg, 2),
		     sha256 <- get_hash(name, version),
		     deps <- dep_string(elem(pkg, 5)) do
			"""
				#{name} = #{builder} rec {
					name = "#{name}";
					version = "#{version}";

					src = fetchHex {
						pkg = "${name}";
						version = "${version}";
						sha256 = "#{sha256}";
					};

					beamDeps = #{deps};
				};
			"""
		end
	end

	defp wrap(pkgs) do
		"""
		{ pkgs }:
		with pkgs; with beamPackages;

		rec {
		#{pkgs}
		}
		"""
	end
end
