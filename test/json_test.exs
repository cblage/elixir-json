Code.require_file "test_helper.exs", __DIR__

defmodule JsonTest do
  use ExUnit.Case

  test "convert keyword into correct JSON" do
    assert \
      Json.encode([result: "this will be a elixir result"]) \
      == "{\"result\":\"this will be a elixir result\"}"
  end

  test "convert complex keyword into correct JSON" do
    assert \
      Json.encode([this_is_null: nil, this_is_false: false, this_is_a_number: 1234, this_is_an_array: ["a", :b, "c"], this_is_a_subobject: [omg: 1337, sub_sub_array: [1,2,3], sub_sub_object: [woot: 123]]]) \
      == "{\"this_is_null\":null,\"this_is_false\":false,\"this_is_a_number\":1234,\"this_is_an_array\":[\"a\",\"b\",\"c\"],\"this_is_a_subobject\":{\"omg\":1337,\"sub_sub_array\":[1,2,3],\"sub_sub_object\":{\"woot\":123}}}"
  end

  test "convert JSON into correct keyword" do
    assert \
      Json.decode("{\"result\": \"this is awesome\"}") \
      == [result: "this is awesome"]
  end

  test "typeof tuple" do
    assert JsonType.typeof({:tuple, "woot"}) == :array
  end

  test "typeof string" do
    assert JsonType.typeof("woot") == :string
  end

  test "typeof number" do
    assert JsonType.typeof(5) == :number
  end

  test "typeof nil" do
    assert JsonType.typeof(nil) == :null
  end

  test "typeof false" do
    assert JsonType.typeof(false) == :boolean
  end
  
  test "typeof true" do
    assert JsonType.typeof(true) == :boolean
  end

  test "typeof list" do
    assert JsonType.typeof([1, 2, 3]) == :array
  end
  
  test "typeof keyword" do
    assert JsonType.typeof([ name: "Carlos", city: "New York", likes: "Programming" ]) == :object
  end

end
