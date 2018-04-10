Code.require_file("test_helper.exs", __DIR__)

defmodule JSONDecodeTest do
  defmodule DSL do
    def prefix(bitstring) when is_bitstring(bitstring), do: "bitstring containing "
    def prefix(bitstring) when is_list(bitstring), do: "charlist containing "

    defmacro decodes(name, input, output) do
      quote do
        test "decodes " <> prefix(unquote(input)) <> unquote(name) do
          decode_result = JSON.decode(unquote(input))

          case decode_result do
            {:ok, actual} ->
              assert unquote(output) == actual

            decode_result ->
              flunk(
                "Expected {:ok, " <>
                  inspect(unquote(output)) <> "}}, got {" <> inspect(decode_result) <> "}}"
              )
          end
        end
      end
    end

    defmacro cannot_decode(name, input, error_info) do
      quote do
        test "cannot decode " <> prefix(unquote(input)) <> unquote(name) do
          decode_result = JSON.decode(unquote(input))

          case decode_result do
            {:error, actual} ->
              assert unquote(error_info) == actual

            decode_result ->
              flunk(
                "Expected {:error," <>
                  inspect(unquote(error_info)) <> "}}, got {" <> inspect(decode_result) <> "}}"
              )
          end
        end
      end
    end
  end

  defmodule BitstringCases do
    use ExUnit.Case, async: true
    import JSONDecodeTest.DSL

    decodes("null", "null", nil)
    decodes("true", "true", true)
    decodes("false", "false", false)

    decodes("empty string", "\"\"", "")
    decodes("simple string", "\"this is a string\"", "this is a string")
    decodes("unicode string", "\"µ¥ ß†®îñ©\"", "µ¥ ß†®îñ©")
    decodes("quotes", "\"I said, \\\"Hi.\\\"\"", "I said, \"Hi.\"")
    decodes("solidi", "\"\\/ \\\\\"", "/ \\")

    decodes(
      "emoji",
      "\"I \\u2665 emoji! So do you \\ud83c\\uddfa\\ud83c\\uddf8!\"",
      "I ♥ emoji! So do you 🇺🇸!"
    )

    decodes(
      "control characters",
      "\"tab\\tnewline\\ncarriage return\\rform feed\\fend\"",
      "tab\tnewline\ncarriage return\rform feed\fend"
    )

    decodes("unicode escape", "\"star -> \\u272d <- star\"", "star -> ✭ <- star")

    decodes("positive integer", "1337", 1337)
    decodes("positive float", "13.37", 13.37)
    decodes("negative integer", "-1337", -1337)
    decodes("negative float", "-13.37", -13.37)

    decodes("integer with exponent", "98e2", 9800)
    decodes("float with positive exponent", "-1.22783E+4", -12_278.3)
    decodes("float with negative exponent", "903.4e-6", 0.0009034)

    decodes("empty object", "{}", Map.new())

    decodes(
      "simple object",
      "{\"result\": \"this is awesome\"}",
      Enum.into([{"result", "this is awesome"}, ], Map.new())
    )

    decodes("empty array", "  [ ] ", [])
    decodes("simple array", "[1, 2, \"three\", 4]", [1, 2, "three", 4, ])

    decodes("nested array", " [null, [false, \"five\"], [3, true]] ", [
      nil,
      [false, "five"],
      [3, true],
    ])

    decodes("simple object with string keys" , "{\"foo\" : 123}", %{"foo" => 123})

    decodes("simple object containing array" , "{\"foo\" : [1,2,3]}", %{"foo" => [1, 2, 3, ]})
    decodes("simple object containing big array" ,
      "{
           \"foo\" : [
                       1,
                       2,
                       3
                     ]
      }",
      %{"foo" => [1, 2, 3, ]}
    )

    decodes(
      "complex object",
      "{
              \"name\": \"Rafaëlla\",
              \"active\": true,
              \"phone\": \"1.415.555.0000\",
              \"balance\": 1.52E+5,
              \"children\": [
                {\"name\": \"Søren\"},
                {\"name\": \"Éloise\"}
              ]
      }",
      Enum.into(
        [
          {"name", "Rafaëlla"},
          {"active", true},
          {"phone", "1.415.555.0000"},
          {"balance", 1.52e+5},
          {"children",
           [
             Enum.into([{"name", "Søren"}], Map.new()),
             Enum.into([{"name", "Éloise"}], Map.new())
           ]}
        ],
        Map.new()
      )
    )

    cannot_decode("simple object with char keys" , "{'foo' : 123}'", {:unexpected_token, "'foo' : 123}'"})

    cannot_decode("bad literal", "nul", {:unexpected_token, "nul"})

    cannot_decode("unterminated string", "\"Not a full string", :unexpected_end_of_buffer)

    cannot_decode(
      "bad Unicode escape",
      "\"bzzt: \\u27qp wrong\"",
      {:unexpected_token, "qp wrong\""}
    )

    cannot_decode("number with trailing .", "889.foo", {:unexpected_token, ".foo"})

    cannot_decode("open brace", "{", :unexpected_end_of_buffer)

    cannot_decode("bad object", "{foo", {:unexpected_token, "foo"})

    cannot_decode("unterminated object", "{\"foo\":\"bar\"", :unexpected_end_of_buffer)

    cannot_decode(
      "multiple value unterminated object",
      "{\"foo\":\"bar\", \"omg\":",
      :unexpected_end_of_buffer
    )

    cannot_decode("object with missing colon", "{\"foo\" \"bar\"}", {:unexpected_token, "\"bar\"}"})
  end

  defmodule CharlistCases do
    use ExUnit.Case, async: true
    import JSONDecodeTest.DSL

    decodes("null", 'null', nil)
    decodes("true", 'true', true)
    decodes("false", 'false', false)

    decodes("empty string", '""', "")
    decodes("simple string", '"this is a string"', "this is a string")

    decodes("string with quotes", '"I said, \\"Hi.\\""', "I said, \"Hi.\"")

    decodes("string with unicode escape", '"star -> \\u272d <- star"', "star -> ✭ <- star")

    decodes(
      "emoji",
      '"I \\u2665 emoji! So do you \\ud83c\\uddfa\\ud83c\\uddf8!"',
      "I ♥ emoji! So do you 🇺🇸!"
    )

    decodes("positive integer", '1337', 1337)
    decodes("positive float", '13.37', 13.37)
    decodes("negative integer", '-1337', -1337)
    decodes("negative float", '-13.37', -13.37)

    decodes("integer with exponent", '98e2', 9800)
    decodes("float with positive exponent", '-1.22783E+4', -12_278.3)
    decodes("float with negative exponent", '903.4e-6', 0.0009034)

    decodes("empty object", "{}", Map.new())

    decodes(
      "simple object",
      '{"result": "this is awesome"}',
      Enum.into([{"result", "this is awesome"}, ], Map.new())
    )

    decodes("empty array", '  [ ] ', [])
    decodes("simple array", ' [1, 2, "three", 4] ', [1, 2, "three", 4, ])

    decodes("nested array", '      [null, [false, "five"], [3, true]]       ', [
      nil,
      [false, "five"],
      [3, true]
    ])
    
    decodes("simple object string keys" , '{"foo" : 123}', %{"foo" => 123})
    decodes("simple object containing array" , '{"foo" : [1,2,3]}', %{"foo" => [1,2,3,]})
    decodes("simple object containing big array" ,
      '{
           "foo" : [
                       1,
                       2,
                       3
                     ]
      }',
      %{"foo" => [1,2,3,]}
    )

    decodes(
      "complex object",
      '{
              "name": "Jenny",
              "active": true,
              "phone": "1.415.555.0000",
              "balance": 1.52E+5,
              "children": [
                {"name": "Penny"},
                {"name": "Elga"}
              ]
             }',
      Enum.into(
        [
          {"name", "Jenny"},
          {"active", true},
          {"phone", "1.415.555.0000"},
          {"balance", 1.52e+5},
          {"children",
           [
             Enum.into([{"name", "Penny"}], Map.new()),
             Enum.into([{"name", "Elga"}], Map.new()),
           ]}
        ],
        Map.new()
      )
    )

    cannot_decode("simple object with char keys" , '{\'foo\' : 123}', {:unexpected_token, '\'foo\' : 123}'})

    cannot_decode("bad literal", 'nul', {:unexpected_token, 'nul'})

    cannot_decode("unterminated string", '"Not a full string', :unexpected_end_of_buffer)

    cannot_decode(
      "string with bad Unicode escape",
      '"bzzt: \\u27qp wrong"',
      {:unexpected_token, 'qp wrong\"'}
    )

    cannot_decode("number with trailing .", '889.foo', {:unexpected_token, '.foo'})

    cannot_decode("open brace", '{', :unexpected_end_of_buffer)

    cannot_decode("bad object", '{foo', {:unexpected_token, 'foo'})

    cannot_decode("unterminated object", '{"foo":"bar"', :unexpected_end_of_buffer)

    cannot_decode(
      "multiple value unterminated object",
      '{"foo":"bar", "omg":',
      :unexpected_end_of_buffer
    )

    cannot_decode("object with missing colon", '{"foo" "bar"}', {:unexpected_token, '"bar"}'})
  end

  defmodule SurrogatePairsCases do
    use ExUnit.Case, async: true
    import JSONDecodeTest.DSL

    decodes("one emoji in bitstring", "\"\\ud83d\\ude0d\"", "😍")

    decodes(
      "several emojis together in bitstring",
      "\"\\ud83d\\ude19\\ud83d\\udc8b\\ud83d\\udc60\\ud83d\\udc96\\ud83d\\udca3\\ud83d\\ude3b\"",
      "😙💋👠💖💣😻"
    )

    decodes("one emoji in charlist", '"\\ud83d\\ude0d"', "😍")

    decodes(
      "several emojis together in charlist",
      '"\\ud83d\\ude19\\ud83d\\udc8b\\ud83d\\udc60\\ud83d\\udc96\\ud83d\\udca3\\ud83d\\ude3b"',
      "😙💋👠💖💣😻"
    )
  end
end
