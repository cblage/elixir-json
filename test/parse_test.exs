Code.require_file "test_helper.exs", __DIR__

defmodule ParseTest do
  use ExUnit.Case
  
  doctest JSON.Parse

  doctest JSON.Parse.String

  doctest JSON.Parse.UnicodeEscape

  doctest JSON.Parse.Number

  doctest JSON.Parse.Array

  doctest JSON.Parse.Object

  doctest JSON.Parse.Value

end
