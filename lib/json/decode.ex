defmodule JSON.Decode do

  defexception Error, message: "Invalid JSON - unknown error"

  defexception UnexpectedTokenError, token: nil do
    def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"

  #32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  defp consume_whitespace([ @acii_space | rest ]), do: consume_whitespace(rest)
  defp consume_whitespace([ ?\t | rest ]), do: consume_whitespace(rest)
  defp consume_whitespace([ ?\r | rest ]), do: consume_whitespace(rest)
  defp consume_whitespace([ ?\n | rest ]), do: consume_whitespace(rest)

  defp consume_whitespace(iolist) when is_list(iolist), do: iolist

  def from_json(bitstring) when is_binary(bitstring) do
    case bitstring_to_list(bitstring) |> from_json do
      { :ok, value } -> { :ok, value }
      { :unexpected_token, tok }       -> { :unexpected_token, iodata_to_binary(tok) }
      { :unexpected_end_of_buffer, s } -> { :unexpected_end_of_buffer, s }
    end
  end

  def from_json(iolist) when is_list(iolist) do
    case consume_whitespace(iolist) |> consume_value do
      { :ok, value, rest } ->
        case consume_whitespace(rest) do
          [] -> { :ok, value }
          _  -> { :unexpected_token, rest }
        end
      { :unexpected_token, tok }       -> { :unexpected_token, tok }
      { :unexpected_end_of_buffer, s } -> { :unexpected_end_of_buffer, s }
    end
  end

  # consume_value: binary -> { nil | true | false | List | HashDict | binary, binary }

  defp consume_value([ ?n, ?u, ?l, ?l  | rest ]), do: { :ok, nil,   rest }
  defp consume_value([ ?t, ?r, ?u, ?e  | rest ]), do: { :ok, true,  rest }
  defp consume_value([ ?f, ?a, ?l, ?s, ?e | rest ]), do: { :ok, false, rest }

  defp consume_value([ ?[ | rest ]), do: consume_whitespace(rest) |> consume_array_contents
  defp consume_value([ ?{ | rest ]), do: consume_whitespace(rest) |> consume_object_contents
  defp consume_value([ ?" | rest ]), do: consume_string_contents(rest)

  defp consume_value([ ?- , number | rest]) when number in ?0..?9, do: consume_number([ ?- , number | rest])
  defp consume_value([ number | rest]) when number in ?0..?9, do: consume_number([ number | rest])

  defp consume_value([ ]), do:  { :unexpected_end_of_buffer, "" }
  defp consume_value(json), do: { :unexpected_token, json }

  # Array Parsing

  ## consume_array_contents: { List, binary } -> { List, binary }
  defp consume_array_contents(json) when is_list(json), do: consume_array_contents([], json)

  defp consume_array_contents(acc, [ ?] | rest ]), do: {:ok, Enum.reverse(acc), rest }
  defp consume_array_contents(_, [] ), do: { :unexpected_end_of_buffer, "" }

  defp consume_array_contents(acc, json) do
    consume_array_value_result = consume_whitespace(json) |> consume_value
    case consume_array_value_result do
      {:ok, value, after_value } ->
        acc = [ value | acc ]
        after_value = consume_whitespace(after_value)

        case after_value  do
          [ ?, | after_comma ] -> consume_array_contents(acc, consume_whitespace(after_comma))
          _ -> consume_array_contents(acc, after_value)
        end
      _ -> consume_array_value_result #propagate error
    end
  end

  # Object Parsing

  ## consume_object_contents: { Dict, binary } -> { Dict, binary }

  defp consume_object_key(json) when is_list(json) do
    key_result = consume_string_contents(json)
    case key_result do
      {:ok, key, after_key } ->
        case consume_whitespace(after_key) do
          [ ?: | after_colon ] -> {:ok, key, consume_whitespace(after_colon)}
          []    -> { :unexpected_end_of_buffer, "" }
          _     -> { :unexpected_token, consume_whitespace(after_key) }
        end
      _ -> key_result #propagate error
    end
  end

  defp consume_object_value(acc, key, after_key) do
    consume_value_result = consume_value(after_key)
    case consume_value_result do
      {:ok, value, after_value} ->
        acc  = HashDict.put(acc, key, value)
        after_value = consume_whitespace(after_value)
        case after_value do
          [ ?, | after_comma ] ->
            consume_object_contents(acc, consume_whitespace(after_comma))
          _ -> consume_object_contents(acc, after_value)
        end
      _ -> consume_value_result #propagate error
    end
  end

  defp consume_object_contents(json) when is_list(json), do: consume_object_contents(HashDict.new, json)

  defp consume_object_contents(acc, [ ?" | rest]) do
    consume_object_key_result = consume_object_key(rest)
    case consume_object_key_result do
      {:ok, key, after_key} -> consume_object_value(acc, key, after_key)
      _  -> consume_object_key_result #propagate error
    end
  end

  defp consume_object_contents(acc, [ ?} | rest ]), do: { :ok, acc, rest }

  defp consume_object_contents(_, []),   do: { :unexpected_end_of_buffer, "" }
  defp consume_object_contents(_, json), do: { :unexpected_token, json }


  # String Parsing
  defp consume_string_contents(json)  when is_list(json), do: consume_string_contents({[], json})

  #stop conditions
  defp consume_string_contents({ :unexpected_token, s }),         do: { :unexpected_token, s }
  defp consume_string_contents({ :unexpected_end_of_buffer, s }), do: { :unexpected_end_of_buffer, s }
  defp consume_string_contents({ _,  [] }),                       do: { :unexpected_end_of_buffer, "" }
  defp consume_string_contents({ acc, [ ?" | rest ] }), do: {:ok, Enum.reverse(acc) |> iodata_to_binary, rest }

  #parsing
  defp consume_string_contents({ acc, [ ?\\, ?f  | rest ]}), do: consume_string_contents({ [ ?\f | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?n  | rest ]}), do: consume_string_contents({ [ ?\n | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?r  | rest ]}), do: consume_string_contents({ [ ?\r | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?t  | rest ]}), do: consume_string_contents({ [ ?\t | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?"  | rest ]}), do: consume_string_contents({ [ ?"  | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?\\ | rest ]}), do: consume_string_contents({ [ ?\\ | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?/  | rest ]}), do: consume_string_contents({ [ ?/  | acc ], rest })
  defp consume_string_contents({ acc, [ ?\\, ?u  | rest ]}), do: consume_unicode_escape({ acc, rest }) |> consume_string_contents

  defp consume_string_contents({ acc, [ c | rest ]}), do: consume_string_contents { [ c | acc ], rest }

  defp consume_unicode_escape({ acc, [ a, b, c, d | rest ] }) do
    first_four_characters = [ a, b, c, d ]
    case JSON.Numeric.to_integer_from_hex(first_four_characters) do
      { converted, [] } -> {[ << converted :: utf8 >> | acc ], rest }
      { _, unexpected_tokens } -> { :unexpected_token, unexpected_tokens }
      _ -> { :unexpected_token, first_four_characters }
    end
  end

  # if theres not enough 4 chars to match above pattern
  defp consume_unicode_escape(_), do: {:unexpected_end_of_buffer, ""}


  #Number parsing
  defp consume_number(json) when is_list(json) do
    case JSON.Numeric.to_numeric(json) do
      { converted, rest } -> { :ok, converted, rest }
      _ -> { :unexpected_token, json }
    end
  end
end
