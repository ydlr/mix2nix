defmodule Mix2nix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix2nix,
      version: "0.1.6",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Mix2nix.CLI],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:hex_core, "~> 0.9"},
      {:hackney, "~> 1.18"},
      {:temp, "~> 0.4"}
    ]
  end
end
