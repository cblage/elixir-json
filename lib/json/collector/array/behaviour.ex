defmodule JSON.Collector.Array.Behaviour do
  defmacro __using__(_) do
    quote do
      @behaviour JSON.Collector.Array

      def close(acc), do: acc

      defoverridable close: 1
    end
  end
end
