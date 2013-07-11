defmodule Json do

  def encode(item) do
    JsonType.encode(item)
  end

  def decode(item) do
    raise "not implemented"
  end

end
