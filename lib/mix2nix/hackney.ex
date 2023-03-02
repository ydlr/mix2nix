defmodule Mix2nix.Hackney do
  @behaviour :hex_http
  def request(mtd, uri, reqhrs, reqbody, _) do
    f =
      if reqbody && reqbody != :undefined do
        &:hackney.request(&1, &2, Map.to_list(&3), reqbody)
      else
        &:hackney.request(&1, &2, Map.to_list(&3))
      end

    with {:ok, 200 = ss, reshrs, ref} <- f.(mtd, uri, reqhrs),
         {:ok, resbody} <- :hackney.body(ref) do
      {:ok, {ss, Map.new(reshrs), resbody}}
    end
  end
end
