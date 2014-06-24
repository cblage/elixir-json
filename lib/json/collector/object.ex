defmodule JSON.Collector.Object do
  @moduledoc """
  Defines the behaviour that a JSON Object collector should implement to be used by Elixir JSON
  """
  use Behaviour

  @opaque t :: :json_collector_object

  @doc """
  Responsible for creating an empty instance of the object collector
  """
  defcallback new :: Enumerable.t

  @doc """
  Responsible for adding items to the object collector
  """
  defcallback put(acc :: Enumerable.t, key :: any, value :: any) :: Enumerable.t

  @doc """
  Responsible for "closing" the object collector, performing any needed actions after done adding items to it
  """
  defcallback close(acc :: Enumerable.t) :: Enumerable.t
end
