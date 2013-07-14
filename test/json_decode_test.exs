Code.require_file "test_helper.exs", __DIR__

defmodule JSONDecodeTest do
  use ExUnit.Case

  test "convert JSON string into correct Elixir string" do
    assert \
      JSON.decode(" \"this is a string\" ") \
      == "this is a string"
  end

  test "convert a positive JSON integer into correct Elixir number" do
    assert \
      JSON.decode(" 1337 ") \
      == 1337
  end

  test "convert a positive JSON float into correct Elixir number" do
    assert \
      JSON.decode(" 13.37 ") \
      == 13.37
  end

  test "convert a negative JSON integer into correct Elixir number" do
    assert \
      JSON.decode(" -1337 ") \
      == -1337
  end

  test "convert a negative JSON float into correct Elixir number" do
    assert \
      JSON.decode(" -13.37 ") \
      == -1337
  end

  test "convert JSON object into correct Elixir keyword" do
    assert \
      JSON.decode("{\"result\": \"this is awesome\"}") \
      == [result: "this is awesome"]
  end

  test "convert JSON array into correct Elixir array" do
    assert \
      JSON.decode("[1, 2, 3, 4]") \
      == [1, 2, 3, 4]
  end

  test "convert JSON empty array into correct Elixir empty array" do
    assert \
      JSON.decode("[]") \
      == []
  end
  
  #Maybe this should be empty tuple?
  test "convert JSON empty object into correct Elixir empty array" do
    assert \
      JSON.decode("{}") \
      == []
  end



end
