defmodule ElixirJSON_125_SNAPSHOT.Mixfile do
  use Mix.Project

  @version "1.2.5"

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
      preferred_cli_env: ["bench.encode": :bench, "bench.decode": :bench, docs: :docs, coveralls: :test, test: :test],
    ]
  end

  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:dev), do:  [] ++ applications(:default)
  defp applications(_all), do: [:logger]

  def deps(_) do
    [
      {:inch_ex, ">=0.0.0", only: [:dev, :test], optional: true},
      {:benchee, "~> 0.8", only: [:bench, :dev, :test, :prod], optional: true},
      {:benchee_html, "~> 0.1", only: [:bench, :dev, :test, :prod], optional: true},
      {:poison, "~> 3.0", only: [:bench, :dev, :test, :prod], optional: true,},
      {:exjsx, "~> 4.0", only: [:bench, :test, :dev, :prod], optional: true},
      {:tiny, "~> 1.0", only: [:bench, :dev, :test, :prod], optional: true, runtime: false},
      {:jsone, "~> 1.4", only: [:bench, :dev,:test, :prod], optional: true, runtime: false},
      {:jason, "~> 1.0", only: [:bench, :dev, :test, :prod], optional: true, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false, optional: true},
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false, optional: true},
      {:excoveralls, "~> 0.8", only: :test, optional: true, runtime: false},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false, optional: true},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false, optional: true},
    ]
  end

  defp aliases() do
    [
      "bench.encode": ["run bench/encode.exs"],
      "bench.decode": ["run bench/decode.exs"],
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
        "README.md",
      ],
    ]
  end

  def package do
    [
      maintainers: ["cblage"],
      licenses: ["BSD 3-Clause"],
      links: %{"GitHub" => "https://github.com/cblage/elixir-json"},
    ]
  end
end
