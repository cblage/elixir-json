defmodule JSON do

  def encode(item) do
    JSON.Encode.to_json(item)
  end

  @doc """
  Decode a String to an Erlang object
  """
  def decode(json_string), do: JSON.Decode.decode(json_string)

end
