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


end
