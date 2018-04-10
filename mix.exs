defmodule ElixirJSON_200_SNAPSHOT.Mixfile do
  use Mix.Project

  @version "1.1.0"

  def project do
    [
      app: :json,
      version: @version,
      elixir: "~> 1.6",
      deps: deps(Mix.env()),
      description: "Native Elixir library for JSON encoding and decoding",
      package: package(),
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "https://hex.pm/packages/json",
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
      docs: docs(),
      aliases: aliases(),
      preferred_cli_env: ["bench.encode": :bench, "bench.decode": :bench, docs: :docs, coveralls: :test],
    ]
  end

  def application() do
    [
      extra_applications: []
    ]
  end

  def deps(_) do
    [
      {:async, "~> 1.0", app: false, override: true},
      #{:inch_ex, github: "cblage/inch_ex", branch: "master", only: [:dev, :test], runtime: false},
      {:inch_ex, ">=0.0.0", only: [:dev, :test]},
      {:parallel_stream, "~> 1.0"},
      {:stream_data, "~> 0.4.2"},
      #{:swarm, "~> 3.3"},
      {:decimal, "~> 1.0", optional: true},
      {:benchee, "~> 0.8", only: :bench, override: true},
      {:benchee_html, "~> 0.1", only: :bench, override: true},
      {:poison, "~> 3.0", only: [:bench, :dev, :test], override: true},
      {:exjsx, "~> 4.0", only: [:bench, :test], override: true},
      {:tiny, "~> 1.0", only: :bench, override: true},
      {:jsone, "~> 1.4", only: :bench, override: true},
      {:jason, "~> 1.0", only: :bench, override: true},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      #{:distillery, "~> 1.5", runtime: false},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      #{:credo, github: "cblage/credo", branch: "master", only: [:dev, :test], runtime: false},
      {:credo, ">=0.0.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp aliases() do
    [
      "bench.encode": ["run bench/encode.exs"],
      "bench.decode": ["run bench/decode.exs"]
    ]
  end

  defp dialyzer() do
    [
      ignore_warnings: "dialyzer.ignore"
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "JSON",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/json",
      source_url: "https://github.com/cblage/elixir-json",
      extras: [
        "README.md"
      ]
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
