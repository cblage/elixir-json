defmodule JSON.Collector.Array.List do
  @behaviour JSON.Collector.Array

  def create(), do: []

  def put(acc, value), do: [ value | acc ]

  def close(acc), do: Enum.reverse(acc)
end
