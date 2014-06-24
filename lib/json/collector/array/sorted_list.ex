defmodule JSON.Collector.Array.SortedList do
  @behaviour JSON.Collector.Array

  def new, do: []

  def put(acc, value), do: [ value | acc ]

  def close(acc), do: Enum.reverse(acc)
end
