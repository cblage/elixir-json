defmodule Json do

  def encode(item) do
    ElixirToJson.encode(item)
  end

  def decode(item) do
    raise "not implemented"
  end

end
