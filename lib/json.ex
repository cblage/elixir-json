defmodule JSON do

  def encode(item) do
    JSON.Encode.to_json(item)
  end

  def decode(item) do
    JSON.Decode.from_json(item)
  end

end
