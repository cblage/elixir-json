defmodule JSON.Logger do
  @moduledoc """
  Exposes separate log level configuration so developers can set logging
  verbosity for json library

  To configure log level only for json library, add folowing line in config file

      use Mix.Config
      # to make json be very verbose
      config :json, log_level: :debug
      # to make json be silent
      config :json, log_level: :error
  """
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

  @doc """
  Logs given message to logger at given log level

  Supported log levels are:
  - `:debug` - All messages are logged
  - `:info` - only :info, :warn and :error messages are logged
  - `:warn` - only :warn and :error messages are logged
  - `:error` - only :error messages are logged
  """
  defmacro log(level, message) do
    quote bind_quoted: [level: level, message: message] do
      if level in JSON.Logger.allowed_levels() do
        Logger.log(level, message)
      end
    end
  end
end
