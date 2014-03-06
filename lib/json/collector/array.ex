defmodule JSON.Collector.Array do 
  @moduledoc """
  Defines the behaviour that a JSON Array collector should implement to be used by Elixir JSON
  """
  use Behaviour

  @opaque t :: :json_collector_array

  @doc """
  Responsible for creating an empty instance of the array collector
  """
  defcallback create() :: Enumerable.t

  @doc """
  Responsible for adding items to the array collector
  """
  defcallback put(acc :: Enumerable.t, value :: any) :: Enumerable.t

  @doc """
  Responsible for "closing" the array collector, performing any actions after done adding items to it
  """
  defcallback close(acc :: Enumerable.t) :: Enumerable.t
end
