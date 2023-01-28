defmodule Mix2nix.MixProject do
	use Mix.Project

	def project do
		[
			app: :mix2nix,
			version: "0.1.6",
			elixir: "~> 1.9",
			start_permanent: Mix.env() == :prod,
			escript: [main_module: Mix2nix.CLI]
		]
	end

	# Run "mix help compile.app" to learn about applications.
	def application do
		[
			extra_applications: [:logger]
		]
	end
end
