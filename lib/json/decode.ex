defmodule JSON.Decode do

  import String, only: [lstrip: 1, rstrip: 1]

  defexception UnexpectedTokenError, token: nil do
    def message(exception) do
      "Invalid JSON - unexpected token >>#{exception.token}<<"
    end
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"

  def from_json(s) when is_binary(s) do
    case lstrip(s) |> consume_value do
      { :unexpected_token, tok }        -> { :unexpected_token, tok }
      { :unexpected_end_of_buffer, "" } -> { :unexpected_end_of_buffer, "" }
      { value, rest } ->
        case rstrip(rest) do
          "" -> { :ok, value }
          _  -> { :unexpected_token, rest }
        end
    end
  end

  def from_json!(s) when is_binary(s) do
    case from_json(s) do
      { :unexpected_token, tok }       -> raise JSON.Decode.UnexpectedTokenError, token: tok
      { :unexpected_end_of_buffer, _ } -> raise JSON.Decode.UnexpectedEndOfBufferError
      { :ok, value }                   -> value
    end
  end

  # consume_value: binary -> { nil | true | false | List | HashDict | binary, binary }

  defp consume_value("null"  <> rest), do: { nil,   rest }
  defp consume_value("true"  <> rest), do: { true,  rest }
  defp consume_value("false" <> rest), do: { false, rest }

  defp consume_value(s) when is_binary(s) do
    case s do
      << ?[, rest :: binary >>                     -> consume_array_contents { [], lstrip(rest) }
      << ?{, rest :: binary >>                     -> consume_object_contents { HashDict.new, lstrip(rest) }
      << ?-, m, rest :: binary >> when m in ?0..?9 -> JSON.Numeric.to_numeric << ?-, m, rest :: binary >>
      << m, rest :: binary >>     when m in ?0..?9 -> JSON.Numeric.to_numeric << m, rest :: binary >>
      << ?", rest :: binary >>                     -> consume_string { [], rest }
      _ ->
        if String.length(s) == 0 do
          { :unexpected_end_of_buffer, "" }
        else 
          { :unexpected_token, s }
        end
    end
  end

  # Array Parsing

  ## consume_array_contents: { List, binary } -> { List, binary }

  defp consume_array_contents { acc, << ?], after_close :: binary >> } do
    { Enum.reverse(acc), after_close }
  end

  defp consume_array_contents { acc, json } do
    { value, after_value } = consume_value(lstrip(json))
    acc = [ value | acc ]
    after_value = lstrip(after_value)

    case after_value do
      << ?,, after_comma :: binary >> -> consume_array_contents { acc, lstrip(after_comma) }
      << ?], after_close :: binary >> -> consume_array_contents { acc, << ?], after_close :: binary >> }
    end
  end

  # Object Parsing

  ## consume_object_contents: { Dict, binary } -> { Dict, binary }

  defp consume_object_contents { acc, << ?}, rest :: binary >> } do
    { acc, rest }
  end

  defp consume_object_contents { acc, << ?", rest :: binary >> } do
    { key, rest } = consume_string { [], rest }

    case lstrip(rest) do
      << ?:, rest :: binary >> ->
        rest = lstrip(rest)
      <<>> ->
        { :unexpected_end_of_buffer, "" }
      _ ->
        { :unexpected_token, rest }
    end

    { value, rest } = consume_value(rest)

    acc  = HashDict.put(acc, key, value)
    rest = lstrip(rest)

    case rest do
      << ?,, rest :: binary >> -> consume_object_contents { acc, lstrip(rest) }
      << ?}, rest :: binary >> -> consume_object_contents { acc, << ?}, rest :: binary >> }
      <<>>                     -> { :unexpected_end_of_buffer, "" }
      _                        -> { :unexpected_token, rest }
    end
  end

  defp consume_object_contents { _, "" }  do
    { :unexpected_end_of_buffer, "" }
  end

  defp consume_object_contents { _, json } do
    { :unexpected_token, json }
  end

  # String Parsing

  ## consume_number: { List, binary } -> { List | binary, binary }

  defp consume_string { :unexpected_token, s } do
    { :unexpected_token, s }
  end

  defp consume_string { :unexpected_end_of_buffer, s } do
    { :unexpected_end_of_buffer, s }
  end

  defp consume_string { _, "" } do
    { :unexpected_end_of_buffer, "" }
  end

  defp consume_string { acc, json } do
    case json do
      << ?\\, ?f,  rest :: binary >> -> consume_string { [ "\f" | acc ], rest }
      << ?\\, ?n,  rest :: binary >> -> consume_string { [ "\n" | acc ], rest }
      << ?\\, ?r,  rest :: binary >> -> consume_string { [ "\r" | acc ], rest }
      << ?\\, ?t,  rest :: binary >> -> consume_string { [ "\t" | acc ], rest }
      << ?\\, ?",  rest :: binary >> -> consume_string { [ ?"   | acc ], rest }
      << ?\\, ?\\, rest :: binary >> -> consume_string { [ ?\\  | acc ], rest }
      << ?\\, ?/,  rest :: binary >> -> consume_string { [ ?/   | acc ], rest }
      << ?\\, ?u,  rest :: binary >> -> consume_unicode_escape({ acc, rest }) |> consume_string 
      << ?",       rest :: binary >> -> { Enum.reverse(acc) |> iolist_to_binary, rest }
      << c,        rest :: binary >> -> consume_string { [ c | acc ], rest }
    end
  end

  defp consume_unicode_escape { acc, << a, b, c, d, rest :: binary >> } do
    s = << a, b, c, d >>
    case JSON.Numeric.to_integer_from_hex(s) do
      { n, "" } -> { [ << n :: utf8 >> | acc ], rest }
      { _, s  } -> { :unexpected_token, s }
      :error    -> { :unexpected_token, s }
    end
  end

end
