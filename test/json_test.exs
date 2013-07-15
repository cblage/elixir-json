Code.require_file "test_helper.exs", __DIR__

defmodule JsonTest do
  use ExUnit.Case

  test "convert keyword with string into correct JSON" do
    assert \
      JSON.encode([result: "this will be a elixir result"]) \
      == "{\"result\":\"this will be a elixir result\"}"
  end

  test "convert keyword with charlist into correct JSON" do
    assert \
      JSON.encode([result: 'this will not be a string']) \
      == "{\"result\":[116,104,105,115,32,119,105,108,108,32,110,111,116,32,98,101,32,97,32,115,116,114,105,110,103]}"
  end

  test "convert complex keyword into correct JSON" do
    assert \
      JSON.encode([this_is_null: nil, this_is_false: false, this_is_a_number: 1234, this_is_an_array: ["a", :b, "c"], this_is_a_subobject: [omg: 1337, sub_sub_array: [1,2,3], sub_sub_object: [woot: 123]]]) \
      == "{\"this_is_null\":null,\"this_is_false\":false,\"this_is_a_number\":1234,\"this_is_an_array\":[\"a\",\"b\",\"c\"],\"this_is_a_subobject\":{\"omg\":1337,\"sub_sub_array\":[1,2,3],\"sub_sub_object\":{\"woot\":123}}}"
  end


  test "convert JSON object into correct keyword" do
    assert \
      JSON.decode("{\"result\": \"this is awesome\"}") \
      == { :ok, [result: "this is awesome"] }
  end


end
