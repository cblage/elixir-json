defmodule ElixirJSON_140_SNAPSHOT.Mixfile do
  use Mix.Project

  @version "1.4.1"

  def project do
    [
      app: :json,
      version: @version,
      elixir: "~> 1.7",
      deps: deps(Mix.env()),
      description: "The First Native Elixir library for JSON encoding and decoding",
      package: package(),
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "https://hex.pm/packages/json",
      test_coverage: [tool: ExCoveralls],
      docs: docs(),
      preferred_cli_env: [
        docs: :docs,
        coveralls: :test,
        test: :test
      ],
      dialyzer_ignored_warnings: [
        {:warn_umatched_return, {:_, :_}, {:unmatched_return, :_}}
      ]
    ]
  end

  def application do
    [applications: applications(Mix.env())]
  end

  defp applications(:dev), do: [] ++ applications(:default)
  defp applications(_all), do: [:logger]

  def deps(_) do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyzex, "~> 1.2", only: [:dev]},
      {:excoveralls, "~> 0.13.4", only: :test, optional: true, runtime: false}
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
