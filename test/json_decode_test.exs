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

    defmacro cannot_decode(name, input, error, message) do
      quote do
        test "cannot decode " <> unquote(name) do
          case JSON.decode(unquote(input)) do
            { unquote(error), actual } -> assert unquote(message) == actual
            { error, actual } -> flunk "Expected { #{unquote(error)}, #{unquote(message)} }, got { #{error}, #{actual} }"
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
    decodes "string with quotes", "\"I said, \\\"Hi.\\\"\"", "I said, \"Hi.\""
    decodes "string with solidi", "\"\\/ \\\\\"", "/ \\"

    decodes "string with control characters",
            "\"tab\\tnewline\\ncarriage return\\rform feed\\fend\"",
            "tab\tnewline\ncarriage return\rform feed\fend"

    decodes "string with unicode escape",
            "\"star -> \\u272d <- star\"",
            "star -> ✭ <- star"

    decodes "positive integer", "1337", 1337
    decodes "positive float", "13.37", 13.37
    decodes "negative integer", "-1337", -1337
    decodes "negative float", "-13.37", -13.37

    decodes "integer with exponent", "98e2", 9800
    decodes "float with positive exponent", "-1.22783E+4", -12278.3
    decodes "float with negative exponent", "903.4e-6", 0.0009034

    decodes "empty object", "{}", HashDict.new
    decodes "simple object", "{\"result\": \"this is awesome\"}",\
                  Enum.into([{"result", "this is awesome"}], HashDict.new)


    decodes "empty array", "  [   ] ", []
    decodes "simple array", "[ 1, 2, \"three\", 4 ]", [ 1, 2, "three", 4 ]
    decodes "nested array", " [ null, [ false, \"five\" ], [ 3, true ] ] ",\
                            [nil, [false, "five"], [3, true]]

    decodes "complex object",
            "{
              \"name\": \"Rafaëlla\",
              \"active\": true,
              \"phone\": \"1.415.555.0000\",
              \"balance\": 1.52E+5,
              \"children\": [
                { \"name\": \"Søren\" },
                { \"name\": \"Éloise\" }
              ]
             }",
             Enum.into([
              { "name", "Rafaëlla" },
              { "active", true },
              { "phone", "1.415.555.0000" },
              { "balance", 1.52e+5 },
              { "children", [
                Enum.into([{"name", "Søren"}], HashDict.new),
                Enum.into([{"name", "Éloise"}], HashDict.new)
              ] }
            ], HashDict.new)

    cannot_decode "bad literal", "nul",
                  :unexpected_token, "nul"

    cannot_decode "unterminated string", "\"Not a full string",
                  :unexpected_end_of_buffer, ""

    cannot_decode "string with bad Unicode escape", "\"bzzt: \\u27qp wrong\"",
                  :unexpected_token, "qp"

    cannot_decode "number with trailing .", "889.foo", :unexpected_token, ".foo"

    cannot_decode "open brace", "{", :unexpected_end_of_buffer, ""

    cannot_decode "bad object", "{foo", :unexpected_token, "foo"

    cannot_decode "unterminated object", "{\"foo\":\"bar\"",
                  :unexpected_end_of_buffer, ""
    
    cannot_decode "multiple value unterminated object", "{\"foo\":\"bar\", \"omg\":",
                  :unexpected_end_of_buffer, ""

    cannot_decode "object with missing colon", "{\"foo\" \"bar\"}",
                  :unexpected_token, "\"bar\"}"
  end

end
