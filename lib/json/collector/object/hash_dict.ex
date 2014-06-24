defmodule JSON.Collector.Object.HashDict do
  use JSON.Collector.Object.Behaviour

  def new, do: HashDict.new

  def put(acc, key, value), do:  HashDict.put(acc, key, value)

end
