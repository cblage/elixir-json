defmodule JSON.Mixfile do
  use Mix.Project

  def project do
    [ app: :json,
      version: "0.3.2",
      elixir: ">= 1.0.0",
      deps: deps(Mix.env),
      description: "Native Elixir library for JSON encoding and decoding",
      package: package,
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "https://hex.pm/packages/json" ]
  end

  def application, do: []

  def deps(:prod), do: []

  def deps(:docs) do
    deps(:prod) ++ [
      { :ex_doc, github: "elixir-lang/ex_doc" },
      { :earmark, github: "pragdave/earmark" }
    ]
  end

  def deps(_), do: deps(:prod)

  def package do
    [ contributors: ["cblage"],
      licenses: ["BSD 3-Clause"],
      links: %{"GitHub" => "https://github.com/cblage/elixir-json" } ]
  end
end
