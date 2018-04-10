defmodule ElixirJSON_200_SNAPSHOT.Mixfile do
  use Mix.Project

  def project do
    [
      app: :json,
      version: "1.0.4-SNAPSHOT",
      elixir: "~> 1.3",
      deps: deps(Mix.env()),
      description: "Native Elixir library for JSON encoding and decoding",
      package: package(),
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "https://hex.pm/packages/json",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test], ]
  end

  def application, do: []

  def deps(_) do
    [
      #{:async, "~> 1.0", app: false, override: true},
      #{:inch_ex, github: "cblage/inch_ex", branch: "master", only: [:dev, :test], runtime: false},
      #{:inch_ex, ">=0.0.0"},
      #{:parallel_stream, "~> 1.0"},
      #{:stream_data, "~> 0.4.2"},
      #{:swarm, "~> 3.3"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      #{:distillery, "~> 1.5", runtime: false},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      #{:credo, github: "cblage/credo", branch: "master", only: [:dev, :test], runtime: false},
      {:credo, ">=0.0.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end


  def package do
    [
      maintainers: ["cblage"],
      licenses: ["BSD 3-Clause"],
      links: %{"GitHub" => "https://github.com/cblage/elixir-json"}
    ]
  end
end
