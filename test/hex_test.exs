Code.require_file "test_helper.exs", __DIR__

defmodule HexTest do
  use ExUnit.Case

  test "is_hex? is false for non-hex strings" do
    assert JSON.Hex.is_hex?("f6o") == false
  end

  test "is_hex? is true for hex strings" do
    assert JSON.Hex.is_hex?("12be9Fd001cb")
    assert JSON.Hex.is_hex?("94")
  end

  test "to_integer parses hex strings" do
    assert JSON.Hex.to_integer("94") == 148
    assert JSON.Hex.to_integer("c2f") == 3119
  end

end
