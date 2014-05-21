defmodule JSON.Collector.Object.Behaviour do
  defmacro __using__(_) do
    quote do
      @behaviour JSON.Collector.Object

      def close(acc), do: acc

      defoverridable close: 1
    end
  end
end
