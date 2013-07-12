Code.require_file "test_helper.exs", __DIR__

defmodule ElixirToJsonTypesTest do
  use ExUnit.Case

  test "typeof tuple" do
    assert ElixirToJson.typeof({:tuple, "woot"}) == :array
  end

  test "typeof string" do
    assert ElixirToJson.typeof("woot") == :string
  end

  test "typeof number" do
    assert ElixirToJson.typeof(5) == :number
  end

  test "typeof nil" do
    assert ElixirToJson.typeof(nil) == :null
  end

  test "typeof false" do
    assert ElixirToJson.typeof(false) == :boolean
  end
  
  test "typeof true" do
    assert ElixirToJson.typeof(true) == :boolean
  end

  test "typeof list" do
    assert ElixirToJson.typeof([1, 2, 3]) == :array
  end
  
  test "typeof keyword" do
    assert ElixirToJson.typeof([ name: "Carlos", city: "New York", likes: "Programming" ]) == :object
  end

end
