defmodule Mix2nix.Env do
  @shield 64 |> :crypto.strong_rand_bytes() |> Base.encode64() |> String.to_atom()
  @enforce_keys [
    :pkg,
    :vsn,
    :org,
    :prv,
    :pub,
    :url
  ]
  defstruct @enforce_keys

  @spec new([String.t()]) :: %__MODULE__{} | nil
  def new(argv) do
    with pkg when is_binary(pkg) <- argv[:hex_pkg_get],
         vsn when is_binary(vsn) <- argv[:hex_pkg_vsn],
         org when is_nil(org) or is_binary(org) <- argv[:hex_pkg_org],
         prv when is_nil(prv) or is_binary(prv) <- argv[:hex_key_prv],
         pub when is_nil(pub) or is_binary(pub) <- argv[:hex_key_pub],
         url when is_nil(url) or is_binary(url) <- argv[:hex_srv_url] do
      %__MODULE__{
        pkg: pkg,
        vsn: vsn,
        org: org,
        prv: shield(prv),
        pub: pub,
        url: url
      }
    else
      _ -> nil
    end
  end

  @doc """
  Makes the sensitive data unshowable, so it will never appear in
  elixir inspects or erlang stacktraces. We can safely
  pass it around and write to any logs directly or indirectly
  without possibility of data leak. The only way to get data back
  is to apply `unshield` function to it, so it's very easy to
  see and control places in a source code
  where data is unshielded.
  """
  def shield(x) do
    (x && fn @shield -> x end) || x
  end

  @doc """
  Unpacks shielded container with sensitive data. Use only in
  places where sensitive data is needed for something.
  """
  def unshield(x) do
    (x && x.(@shield)) || x
  end
end
