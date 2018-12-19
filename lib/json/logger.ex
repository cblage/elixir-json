defmodule Json.Logger do
  require Logger
  @levels [:debug, :info, :warn, :error]
  @level Application.get_env(:json, :log_level, :info)

  @allowed_levels @levels
                  |> Enum.reverse()
                  |> Enum.reduce_while([], fn l, acc ->
                    if l == @level do
                      {:halt, [@level | acc]}
                    else
                      {:cont, [l | acc]}
                    end
                  end)
                  |> Enum.reverse()

  @spec allowed_levels() :: [:debug | :error | :info | :warn, ...]
  def allowed_levels(), do: @allowed_levels

  defmacro log(level, message) do
    quote bind_quoted: [level: level, message: message] do
      if level in Json.Logger.allowed_levels() do
        Logger.log(level, message)
      end
    end
  end
end
