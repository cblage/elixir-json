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

    defmacro cannot_decode(name, input, exception, message) do
      quote do
        test "cannot decode " <> unquote(name) do
          assert_raise unquote(exception), unquote(message), fn ->
            JSON.decode!(unquote(input))
          end
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
    decodes "unicode string", "\"µ¥ ß†®îñ©\"",  "µ¥ ß†®îñ©"

    decodes "positive integer", "1337", 1337
    decodes "positive float", "13.37", 13.37
    decodes "negative integer", "-1337", -1337
    decodes "negative float", "-13.37", -13.37

    decodes "empty object", "{}", HashDict.new
    decodes "simple object", "{\"result\": \"this is awesome\"}",\
                  HashDict.put(HashDict.new, "result", "this is awesome")

    decodes "empty array", "  [   ] ", []
    decodes "simple array", "[ 1, 2, \"three\", 4 ]", [ 1, 2, "three", 4 ]
    decodes "nested array", " [ null, [ false, \"five\" ], [ 3, true ] ] ",\
                            [nil, [false, "five"], [3, true]]

    decodes "complex object",
            "{
              \"name\": \"Rafaëlla\",
              \"active\": true,
              \"children\": [
                { \"name\": \"Søren\" },
                { \"name\": \"Éloise\" }
              ]
             }",
             HashDict.new([
              { "name", "Rafaëlla" },
              { "active", true },
              { "children", [
                HashDict.new([ { "name", "Søren" } ]),
                HashDict.new([ { "name", "Éloise" } ])
              ] }
            ])

    cannot_decode "bad literal", "nul",
                  JSON.Decode.UnexpectedTokenError, %r{nul}
    cannot_decode "unterminated string", "\"Not a full string",
                  JSON.Decode.UnexpectedEndOfBufferError, %r{buffer}
    cannot_decode "unterminated object", "{\"foo\":\"bar\"",
                  JSON.Decode.UnexpectedEndOfBufferError, %r{buffer}
    cannot_decode "object with missing colon", "{\"foo\" \"bar\"}",
                  JSON.Decode.UnexpectedTokenError, %r{bar}
  end

end
