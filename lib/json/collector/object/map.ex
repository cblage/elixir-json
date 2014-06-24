defmodule JSON.Collector.Object.Map do
  use JSON.Collector.Object.Behaviour

  def new, do: %{}

  def put(acc, key, value), do:  Map.put(acc, key, value)

end
