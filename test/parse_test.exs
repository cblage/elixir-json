Code.require_file "test_helper.exs", __DIR__

defmodule ParseTest do
  use ExUnit.Case

  doctest JSON.Parser.Bitstring

  doctest JSON.Parser.Charlist
  doctest JSON.Parser.Charlist.String
  doctest JSON.Parser.Charlist.Number
  doctest JSON.Parser.Charlist.Array
  doctest JSON.Parser.Charlist.Object
end
