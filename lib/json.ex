defmodule JSON do

  def encode(item) do
    JSON.Encode.to_json(item)
  end

  def decode(<< ?", rest :: binary >>) do
    decode_rest_of_string(rest, [])
  end

  def decode(_) do
    raise "not implemented"
  end

  defp decode_rest_of_string("\"", acc) do
    { :ok, to_binary(Enum.reverse(acc)) }
  end

  defp decode_rest_of_string(<< x, rest :: binary >>, acc) do
    decode_rest_of_string(rest, [ x | acc ])
  end

end
