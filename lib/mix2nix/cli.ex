defmodule Mix2nix.CLI do
  def main(argv0 \\ []) do
    argv =
      argv0 ++
        ("MIX2NIX_ARGV"
         |> System.get_env("")
         |> String.split(" ", trim: true))

    {opt, args, _invalid} =
      OptionParser.parse(argv,
        switches: [
          hex_get_pkg: :string,
          hex_pkg_vsn: :string,
          hex_api_key: :string,
          version: :boolean,
          help: :boolean
        ]
      )

    hex_get_pkg = opt[:hex_get_pkg]

    cond do
      opt[:version] ->
        vsn = Application.spec(:mix2nix, :vsn) |> to_string()
        IO.puts("mix2xix " <> vsn)

      opt[:help] ->
        print_usage() |> IO.puts()

      hex_get_pkg ->
        hex_pkg_vsn = opt[:hex_pkg_vsn]
        :ok = start_apps()

        tar =
          Mix2nix.hex_get_pkg(
            pkg: hex_get_pkg,
            vsn: opt[:hex_pkg_vsn],
            key: opt[:hex_api_key]
          )

        :ok = File.write!("#{hex_get_pkg}-#{hex_pkg_vsn}.tar", tar)

      true ->
        case lock_file_from_args(args) do
          {:error, e} ->
            IO.puts("#{e}")
            System.halt(1)

          {:ok, lock} ->
            :ok = start_apps()

            lock
            |> Mix2nix.process()
            |> IO.puts()
        end
    end
  end

  def start_apps do
    [:hackney]
    |> Enum.each(&({:ok, _} = Application.ensure_all_started(&1)))
  end

  defp lock_file_from_args([lock]) do
    case File.exists?(lock) do
      true ->
        {:ok, lock}

      false ->
        {:error, "Lock file #{lock} not found."}
    end
  end

  defp lock_file_from_args([_lock | _tail]) do
    {:error, "Extra arguments not supported. Expected Usage: `mix2nix [filename]`"}
  end

  defp lock_file_from_args([]) do
    case File.exists?("mix.lock") do
      true ->
        {:ok, "mix.lock"}

      false ->
        {:error, "Unable to find mix.lock file in current directory."}
    end
  end

  defp print_usage() do
    ~S"""
    Usage:
    mix2nix [file]

    Generates a set of nix package definitions from a mix.lock file. If no file
    is specified, it will search the current directory.

    Options:
    --help     Show this help message.
    --version  Show the application version.
    """
  end
end
