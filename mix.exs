defmodule JSON.Mixfile do
  use Mix.Project

  def project do
    [ app: :json,
      version: "0.3.0-dev",
      elixir: "~> 0.12.0",
      deps: deps(Mix.env),
      source_url: "https://github.com/cblage/elixir-json",
      homepage_url: "http://expm.co/json" ]
  end

  def application, do: []
  
  def deps(:prod), do: []

  def deps(:docs) do
    deps(:prod) ++ [ { :ex_doc, github: "elixir-lang/ex_doc" } ]
  end

  def deps(_), do: deps(:prod)
end
