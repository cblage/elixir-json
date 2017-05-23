defmodule JSON.Mixfile do
  use Mix.Project

  def project do
    [ app: :json,
      version: "1.0.2",
      elixir: "~> 1.4",
      deps: deps(Mix.env),
      description: "Native Elixir library for JSON encoding and decoding",
      package: package(),
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "https://hex.pm/packages/json" ]
  end

  def application, do: []

  def deps(:prod) do
    [
      { :ex_doc, ">= 0.0.0", only: :dev},
      { :earmark, ">= 0.0.0", only: :dev}
    ]
  end

  def deps(_), do: deps(:prod)

  def package do
    [ maintainers: ["cblage"],
      licenses: ["BSD 3-Clause"],
      links: %{"GitHub" => "https://github.com/cblage/elixir-json" } ]
  end
end
