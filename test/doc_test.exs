Code.require_file("test_helper.exs", __DIR__)

defmodule DocTest do
  use ExUnit.Case

  doctest JSON

  doctest JSON.Encoder

  doctest JSON.Parser
  doctest JSON.Parser.String
  doctest JSON.Parser.Number
  doctest JSON.Parser.Array
  doctest JSON.Parser.Object
end
