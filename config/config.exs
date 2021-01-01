# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  level: :warning,
  compile_time_purge_matching: [
    [level_lower_than: :warning]
  ]

config :json, log_level: :warning
