Code.require_file "test_helper.exs", __DIR__

defmodule JSONDecodeTest do

  defmodule DSL do
    defmacro decodes(name, input, output) do
      quote do
        test "decodes " <> unquote(name) do
          assert JSON.decode(unquote(input)) == {:ok, unquote(output)}
        end
      end
    end
  end

  defmodule Cases do
    use ExUnit.Case
    import JSONDecodeTest.DSL

    decodes "null",  "null",  nil
    decodes "true",  "true",  true
    decodes "false", "false", false

    decodes "empty string", "\"\"", ""
    decodes "simple string", "\"this is a string\"", "this is a string"

    decodes "positive integer", "1337", 1337
    decodes "positive float", "13.37", 13.37
    decodes "negative integer", "-1337", -1337
    decodes "negative float", "-13.37", -13.37

    decodes "empty object", "{}", HashDict.new
    decodes "simple object", "{\"result\": \"this is awesome\"}", [result: "this is awesome"]

    decodes "empty array", "  [   ] ", []
    decodes "simple array", "[ 1, 2, \"three\", 4 ]", [ 1, 2, "three", 4 ]
  end

end
