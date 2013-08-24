defmodule JSON.Decode do

  import String, only: [lstrip: 1, rstrip: 1]

  defexception UnexpectedTokenError, token: nil do
    def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"

  def from_json(s) when is_binary(s) do
    case lstrip(s) |> consume_value do
      { :unexpected_token, tok }        -> { :unexpected_token, tok }
      { :unexpected_end_of_buffer, "" } -> { :unexpected_end_of_buffer, "" }
      { :ok, value, rest } ->
        case rstrip(rest) do
          "" -> { :ok, value }
          _  -> { :unexpected_token, rest }
        end
    end
  end

  def from_json!(s) when is_binary(s) do
    case from_json(s) do
      { :ok, value }                   -> value
      { :unexpected_token, tok }       -> raise JSON.Decode.UnexpectedTokenError, token: tok
      { :unexpected_end_of_buffer, _ } -> raise JSON.Decode.UnexpectedEndOfBufferError
    end
  end

  # consume_value: binary -> { nil | true | false | List | HashDict | binary, binary }

  defp consume_value("null"  <> rest), do: { :ok, nil,   rest }
  defp consume_value("true"  <> rest), do: { :ok, true,  rest }
  defp consume_value("false" <> rest), do: { :ok, false, rest }

  defp consume_value(json) when is_binary(json) do
    case json do
      << ?[, after_square_bracket :: binary >> -> lstrip(after_square_bracket) |> consume_array_contents
      << ?{, after_curly_bracket  :: binary >> -> lstrip(after_curly_bracket)  |> consume_object_contents 
      << ?", after_double_quote :: binary >>   -> consume_string_contents(after_double_quote)
      << ?-, number, _ :: binary >> when number in ?0..?9 -> consume_number(json)
      << number, _ :: binary >>     when number in ?0..?9 -> consume_number(json)
      "" -> { :unexpected_end_of_buffer, "" }
      _ ->  { :unexpected_token, json }
    end
  end

  # Array Parsing

  ## consume_array_contents: { List, binary } -> { List, binary }
  defp consume_array_contents(json) when is_binary(json), do: consume_array_contents({[], json})
  
  defp consume_array_contents({ acc, << ?], after_close :: binary >> }), do: {:ok, Enum.reverse(acc), after_close }
  defp consume_array_contents({ _, "" }), do: { :unexpected_end_of_buffer, "" }

  defp consume_array_contents({ acc, json }) do
    consume_array_value_result = lstrip(json) |> consume_value
    case consume_array_value_result do 
      {:ok, value, after_value } ->
        acc = [ value | acc ]
        after_value = lstrip(after_value)
        
        case after_value  do
          << ?,, after_comma :: binary >> -> consume_array_contents({ acc, lstrip(after_comma) })
          _ -> consume_array_contents({ acc, after_value})
        end
      _ -> consume_array_value_result #propagate error
    end
  end

  # Object Parsing

  ## consume_object_contents: { Dict, binary } -> { Dict, binary }

  defp consume_object_key(json) when is_binary(json) do
    key_result = consume_string_contents(json)
    case key_result do 
      {:ok, key, after_key } ->
        case lstrip(after_key) do
          << ?:, after_colon :: binary >> -> {:ok, key, lstrip(after_colon)}
          << >> -> { :unexpected_end_of_buffer, "" }
          _     -> { :unexpected_token, lstrip(after_key) }
        end
      _ -> key_result #propagate error
    end
  end

  defp consume_object_value(acc, key, after_key) do
    consume_value_result = consume_value(after_key)
    case consume_value_result do
      {:ok, value, after_value} ->
        acc  = HashDict.put(acc, key, value)
        after_value = lstrip(after_value)
        case after_value do
          << ?,, after_comma :: binary >> -> consume_object_contents({ acc, lstrip(after_comma) })
          _ -> consume_object_contents({ acc, after_value })
        end
      _ -> consume_value_result #propagate error
    end
  end
  
  defp consume_object_contents(json) when is_binary(json), do: consume_object_contents({HashDict.new, json})
  
  defp consume_object_contents({ acc, << ?", json :: binary >> }) do
    consume_object_key_result = consume_object_key(json)
    case consume_object_key_result do
      {:ok, key, after_key} -> consume_object_value(acc, key, after_key)
      _  -> consume_object_key_result #propagate error
    end
  end

  defp consume_object_contents({ acc, << ?}, after_closing_bracket :: binary >> }), do: { :ok, acc, after_closing_bracket }

  defp consume_object_contents({ _, "" }),   do: { :unexpected_end_of_buffer, "" }
  defp consume_object_contents({ _, json }), do: { :unexpected_token, json }


  # String Parsing
  defp consume_string_contents(json)  when is_binary(json), do: consume_string_contents({[], json})

  #stop conditions
  defp consume_string_contents({ :unexpected_token, s }),         do: { :unexpected_token, s }
  defp consume_string_contents({ :unexpected_end_of_buffer, s }), do: { :unexpected_end_of_buffer, s }
  defp consume_string_contents({ _, "" }),                        do: { :unexpected_end_of_buffer, "" }
  defp consume_string_contents({ acc, << ?", rest :: binary >> }), do: {:ok, Enum.reverse(acc) |> iolist_to_binary, rest }
  
  #parsing
  defp consume_string_contents({ acc, json }) do
    case json do
      << ?\\, ?f,  rest :: binary >> -> consume_string_contents({ [ "\f" | acc ], rest })
      << ?\\, ?n,  rest :: binary >> -> consume_string_contents({ [ "\n" | acc ], rest })
      << ?\\, ?r,  rest :: binary >> -> consume_string_contents({ [ "\r" | acc ], rest })
      << ?\\, ?t,  rest :: binary >> -> consume_string_contents({ [ "\t" | acc ], rest })
      << ?\\, ?",  rest :: binary >> -> consume_string_contents({ [ ?"   | acc ], rest })
      << ?\\, ?\\, rest :: binary >> -> consume_string_contents({ [ ?\\  | acc ], rest })
      << ?\\, ?/,  rest :: binary >> -> consume_string_contents({ [ ?/   | acc ], rest })
      << ?\\, ?u,  rest :: binary >> -> consume_unicode_escape({ acc, rest }) |> consume_string_contents 
      << c,        rest :: binary >> -> consume_string_contents { [ c | acc ], rest }
    end
  end

  defp consume_unicode_escape({ acc, << a, b, c, d, rest :: binary >> }) do
    first_four_characters = << a, b, c, d >>
    case JSON.Numeric.to_integer_from_hex(first_four_characters) do
      { converted, "" } -> {[ << converted :: utf8 >> | acc ], rest }
      { _, unexpected_tokens } -> { :unexpected_token, unexpected_tokens }
      _ -> { :unexpected_token, first_four_characters }
    end
  end

  #Number parsing
  defp consume_number(json) when is_binary(json) do
    case JSON.Numeric.to_numeric(json) do
      { converted, rest } -> { :ok, converted, rest }
      _ -> { :unexpected_token, json }
    end
  end
end
