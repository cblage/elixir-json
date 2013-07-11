Code.require_file "test_helper.exs", __DIR__

defmodule JsonTest do
  use ExUnit.Case

  test "convert keyword into correct JSON" do
    assert \
      Json.encode([result: "this will be a elixir result"]) \
      == "{\"result\": \"this will be a elixir result\"}"
  end

  test "convert JSON into correct keyword" do
    assert \
      Json.decode("{\"result\": \"this is awesome\"}") \
      == [result: "this is awesome"]
  end
end
