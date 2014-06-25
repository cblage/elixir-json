defmodule JSON.Collector.Object.Map do
  use JSON.Collector.Object.Behaviour
  
  def create(), do: Map.new

  def put(acc, key, value), do:  Map.put(acc, key|>String.to_atom, value)

end
