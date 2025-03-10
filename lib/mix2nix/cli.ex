defmodule Mix2nix.CLI do
  def main(argv \\ []) do

    {argv_without_env, env_vars} = extract_env_options(argv)

    {opt, args, _invalid} =
      OptionParser.parse(argv_without_env,
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
            |> Mix2nix.process(env_vars)
            |> IO.puts()
        end
    end
  end

  defp extract_env_options(argv) do
    extract_env_options(argv, [], %{})
  end

  defp extract_env_options([], acc_argv, env_vars) do
    {Enum.reverse(acc_argv), env_vars}
  end

  defp extract_env_options(["-e", env_value | rest], acc_argv, env_vars) when is_binary(env_value) do
    {key, value} = parse_env_string(env_value)
    extract_env_options(rest, acc_argv, Map.put(env_vars, key, value))
  end

  defp extract_env_options(["--env", env_value | rest], acc_argv, env_vars) when is_binary(env_value) do
    {key, value} = parse_env_string(env_value)
    extract_env_options(rest, acc_argv, Map.put(env_vars, key, value))
  end

  defp extract_env_options([arg | rest], acc_argv, env_vars) do
    extract_env_options(rest, [arg | acc_argv], env_vars)
  end

  defp parse_env_string(env_string) do
    case String.split(env_string, "=", parts: 2) do
      [key, value] ->
        parsed_value = parse_value(value)
        {key, parsed_value}
      _ ->
        {"", ""}
    end
  end

  defp parse_value(value) do
    value = String.trim(value)

    cond do
      String.starts_with?(value, "\"") && String.ends_with?(value, "\"") ->
        value |> String.slice(1..-2//-1)
      String.starts_with?(value, "'") && String.ends_with?(value, "'") ->
        value |> String.slice(1..-2//-1)
      true ->
        value
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
    mix2nix [options] [file]

    Generates a set of nix package definitions from a mix.lock file. If no file
    is specified, it will search the current directory.

    Options:
    -e, --env KEY=VALUE  Set environment variable(s). Can be used multiple times.
    --help     Show this help message.
    --version  Show the application version.
    """
  end
end
