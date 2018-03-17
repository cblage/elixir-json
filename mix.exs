defmodule ElixirJSON_104_SNAPSHOT.Mixfile do
  use Mix.Project

  def project do
    [
      app: :json,
      version: "1.0.4-SNAPSHOT",
      elixir: "~> 1.0",
      deps: deps(Mix.env()),
      description: "Native Elixir library for JSON encoding and decoding",
      package: package(),
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "https://hex.pm/packages/json"
    ]
  end

  def application, do: []

  def deps(:prod), do: []
  def deps(:dev), do: [ex_doc()]
  def deps(:test), do: [ex_doc()]
  def deps(:docs) do
    [
      {:inch_ex, github: "cblage/inch_ex", branch: "master", only: [:dev, :test], runtime: false},
      {:credo, github: "cblage/credo", branch: "master", only: [:dev, :test], runtime: false},
      ex_doc()
    ]
  end

  defp ex_doc, do: {:ex_doc, "~> 0.16", only: :dev, runtime: false}

  def package do
    [
      maintainers: ["cblage"],
      licenses: ["BSD 3-Clause"],
      links: %{"GitHub" => "https://github.com/cblage/elixir-json"}
    ]
  end
end
