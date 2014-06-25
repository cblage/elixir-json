defmodule JSON.Collector do
  defstruct array: JSON.Collector.Array.List,  object: JSON.Collector.Object.HashDict 
  # record_type array: JSON.Collector.Array.t, object: JSON.Collector.Object.t
  def new, do: %JSON.Collector{}
  def new(:map), do: %JSON.Collector{object: JSON.Collector.Object.Map}
end
