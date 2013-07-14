Code.require_file "test_helper.exs", __DIR__

defmodule JSONDecodeTest do
  use ExUnit.Case

  test "convert JSON into correct keyword" do
    assert \
      JSON.decode("{\"result\": \"this is awesome\"}") \
      == [result: "this is awesome"]
  end


end
