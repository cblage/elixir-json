defmodule JSON do

  def encode(item) do
    JSON.Encode.to_json(item)
  end

  def decode(_) do
    raise "not implemented"
  end

end
