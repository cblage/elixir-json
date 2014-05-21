Code.require_file "test_helper.exs", __DIR__

defmodule ParseTest do
  use ExUnit.Case

  doctest JSON.Parse.Bitstring
  doctest JSON.Parse.Bitstring.String
  doctest JSON.Parse.Bitstring.Number
  doctest JSON.Parse.Bitstring.Array
  doctest JSON.Parse.Bitstring.Object
  doctest JSON.Parse.Bitstring.Value

  doctest JSON.Parse.Charlist
  doctest JSON.Parse.Charlist.String
  doctest JSON.Parse.Charlist.Number
  doctest JSON.Parse.Charlist.Array
  doctest JSON.Parse.Charlist.Object
  doctest JSON.Parse.Charlist.Value
end
