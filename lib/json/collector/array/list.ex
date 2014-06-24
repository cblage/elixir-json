defmodule JSON.Collector.Array.List do
  use JSON.Collector.Array.Behaviour

  def new, do: []

  def put(acc, value), do: [ value | acc ]
end
