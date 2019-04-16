defmodule ElixirJSON_130_SNAPSHOT.Mixfile do
  use Mix.Project

  @version "1.3.0"

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
      preferred_cli_env: [
        docs: :docs,
        coveralls: :test,
        test: :test
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
      {:excoveralls, "~> 0.8", only: :test, optional: true, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false, optional: true},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false, optional: true}
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
