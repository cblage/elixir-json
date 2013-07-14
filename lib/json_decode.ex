defprotocol JSON.Decode do
  
  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """
  def from_json(item)

end

defimpl JSON.Decode, for: BitString do

  def from_json("[]") do 
    []
  end

  def from_json("{}") do 
    []
  end

  def from_json(bitstring) do 
    _accept_any_token(bitstring, nil)
  end

  #Stop condition
  defp _accept_any_token(<<>>, parent) do
    parent
  end

  defp _accept_any_token(bitstring, parent) do
    _consume_whitespace(bitstring)
      |>_process_token(parent)
  end

  # consume whitespace, 32 = ascii space
  defp _consume_whitespace(<< token, tail :: binary>>) when token in [?\t, ?\r, ?\n, 32] do
    _consume_whitespace(tail)
  end

  defp _consume_whitespace(bitstring) when is_bitstring(bitstring) do
    bitstring
  end

  defp _process_token(token, _) do
    raise "Invalid JSON - unexpected token >>#{token}<<"
  end



end
