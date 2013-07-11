defmodule Json do

  def encode(item) do
    "{\"result\": \"this will be json\"}"
  end

  def decode(item) do
    [result: "this will be a elixir result"]
  end

end
