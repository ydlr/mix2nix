defmodule Mix2nix.CLI do
  def main(argv \\ []) do
    {opt, args, _invalid} =
      OptionParser.parse(argv,
        switches: [version: :boolean, help: :boolean]
      )

    cond do
      opt[:version] ->
        vsn = Application.spec(:mix2nix, :vsn) |> to_string()
        IO.puts("mix2nix " <> vsn)

      opt[:help] ->
        print_usage() |> IO.puts()

      true ->
        case lock_file_from_args(args) do
          {:error, e} ->
            IO.puts("#{e}")
            System.halt(1)

          {:ok, lock} ->
            lock
            |> Mix2nix.process()
            |> IO.puts()
        end
    end
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
