defmodule JSON.Logger do
  @moduledoc """
  Exposes separate log level configuration so developers can set logging
  verbosity for json library

  To configure log level only for json library, add following line in config file

      use Mix.Config
      # to make json be very verbose
      config :json, log_level: :debug
      # to make json be silent
      config :json, log_level: :error
  """
  require Logger

  @log_levels [:error, :warn, :info, :debug]

  @spec allowed_levels() :: [Logger.level()]
  def allowed_levels() do
    json_log_level = Application.get_env(:json, :log_level, :info)

    @log_levels
    |> Enum.reduce_while([], fn
      ^json_log_level, acc ->
        {:halt, [json_log_level | acc]}

      l, acc ->
        {:cont, [l | acc]}
    end)
    |> Enum.reverse()
  end

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
      else
        :ok
      end
    end
  end
end
