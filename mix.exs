defmodule Json.Mixfile do
  use Mix.Project

  def project do
    [ app: :json,
      version: "0.0.1.dev",
      elixir: "~> 0.9.4-dev",
      deps: deps,
      source_url: "https://github.com/cblage/elixir-json" ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    []
  end
end
