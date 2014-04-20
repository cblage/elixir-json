Code.require_file "test_helper.exs", __DIR__

defmodule JSONEncodeTest do
  use ExUnit.Case

  doctest JSON.Encode

  test "convert keyword with string into correct JSON" do
    assert \
      JSON.encode([result: "this will be a elixir result"]) \
      == {:ok, "{\"result\":\"this will be a elixir result\"}"}
  end
  
  test "convert keyword with charlist into correct JSON" do
    assert \
      JSON.encode([result: 'this will not be a string']) \
      == {:ok, "{\"result\":[116,104,105,115,32,119,105,108,108,32,110,111,116,32,98,101,32,97,32,115,116,114,105,110,103]}"}
  end

  test "convert complex keyword into correct JSON" do
    assert \
      JSON.encode([this_is_null: nil, this_is_false: false, this_is_a_number: 1234, this_is_an_array: ["a", :b, "c"], this_is_a_subobject: [omg: 1337, sub_sub_array: [1,2,3], sub_sub_object: [woot: 123]]]) \
      == {:ok, "{\"this_is_null\":null,\"this_is_false\":false,\"this_is_a_number\":1234,\"this_is_an_array\":[\"a\",\"b\",\"c\"],\"this_is_a_subobject\":{\"omg\":1337,\"sub_sub_array\":[1,2,3],\"sub_sub_object\":{\"woot\":123}}}"}
  end


  test "convert HashDict into correct JSON" do
    acc = HashDict.new
    acc = HashDict.put(acc, "null",  nil)
    acc = HashDict.put(acc, "false", false)
    acc = HashDict.put(acc, "string", "this will be a string")
    acc = HashDict.put(acc, "number", 1234)
    acc = HashDict.put(acc, "array",  ["a", :b, "c"])
    acc = HashDict.put(acc, "object", [omg: 1337, sub_sub_array: [1,2,3], sub_sub_object: [woot: 123]])
  
  
    assert JSON.encode(acc) \
      == {:ok, "{\"number\":1234,\"false\":false,\"array\":[\"a\",\"b\",\"c\"],\"object\":{\"omg\":1337,\"sub_sub_array\":[1,2,3],\"sub_sub_object\":{\"woot\":123}},\"null\":null,\"string\":\"this will be a string\"}"}
  end

  test "convert keyword with '\\' into correct JSON" do
    assert \
      JSON.encode([result: "\\n"]) == {:ok, "{\"result\":\"\\\\n\"}"}
  end

  test "convert maps into correct JSON" do
    assert \
      JSON.encode(%{a: 1, b: %{b1: 21}}) |> IO.inspect \
      == {:ok, "{\"a\":1,\"b\":{\"b1\":21}}"}
  end
end
