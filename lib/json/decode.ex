defmodule JSON.Decode do

  import String, only: [lstrip: 1, rstrip: 1]

  defexception UnexpectedTokenError, token: nil do
    def message(exception) do
      "Invalid JSON - unexpected token >>#{exception.token}<<"
    end
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"

  def from_json(s) when is_binary(s) do
    { result, rest } = consume_value(lstrip(s))
    unless "" == rstrip(rest) do
      raise UnexpectedTokenError, token: rest
    end
    result
  end

  defp consume_value("null"  <> rest), do: { nil,   rest }
  defp consume_value("true"  <> rest), do: { true,  rest }
  defp consume_value("false" <> rest), do: { false, rest }

  defp consume_value(s) when is_binary(s) do
    case s do
      << ?[, rest :: binary >> ->
        consume_array_contents(lstrip(rest), [])
      << ?{, rest :: binary >> ->
        consume_object_contents(lstrip(rest), HashDict.new)
      << ?-, m, rest :: binary >> when m in ?0..?9 ->
        { number, tail } = consume_number(m - ?0, rest)
        { -1 * number, tail }
      << m, rest :: binary >> when m in ?0..?9 ->
        consume_number m - ?0, rest
      << ?", rest :: binary >> ->
        consume_string rest, []
      _ ->
        if String.length(s) == 0 do
          raise UnexpectedEndOfBufferError
        end
        raise UnexpectedTokenError, token: s
    end
  end

  # Array Parsing

  defp consume_array_contents(<< ?], after_close :: binary >>, acc) do
    { Enum.reverse(acc), after_close }
  end

  defp consume_array_contents(json, acc) do
    { value, after_value } = consume_value(lstrip(json))
    acc = [ value | acc ]
    after_value = lstrip(after_value)

    case after_value do
      << ?,, after_comma :: binary >> ->
        after_comma = lstrip(after_comma)
        consume_array_contents(after_comma, acc)
      << ?], after_close :: binary >> ->
        { Enum.reverse(acc), after_close }
    end
  end

  # Object Parsing

  defp consume_object_contents(<< ?}, rest :: binary >>, acc) do
    { acc, rest }
  end

  defp consume_object_contents(<< ?", rest :: binary >>, acc) do
    { key, rest } = consume_string(rest, [])

    case lstrip(rest) do
      << ?:, rest :: binary >> ->
        rest = lstrip(rest)
      <<>> ->
        raise UnexpectedEndOfBufferError
      _ ->
        raise UnexpectedTokenError, token: rest
    end

    { value, rest } = consume_value(rest)
    acc = HashDict.put(acc, key, value)
    rest = lstrip(rest)

    case rest do
      << ?,, rest :: binary >> ->
        rest = lstrip(rest)
        consume_object_contents(rest, acc)
      << ?}, rest :: binary >> ->
        { acc, rest }
      <<>> ->
        raise UnexpectedEndOfBufferError
      _ ->
        raise UnexpectedTokenError, token: rest
    end
  end

  defp consume_object_contents("", _) do
    raise UnexpectedEndOfBufferError
  end

  defp consume_object_contents(json, _) do
    raise UnexpectedTokenError, token: json
  end

  # Number Parsing

  defp consume_number(n, << m, rest :: binary >>) when m in ?0..?9 do
    consume_number(n * 10 + m - ?0, rest)
  end

  defp consume_number(n, "") do
    { n, "" }
  end

  defp consume_number(n, << ?., rest :: binary >>) do
    { fractional, tail } = consume_fractional(0, 10.0, rest)
    { n + fractional, tail }
  end

  defp consume_number(n, << m, rest :: binary >>) when not m in ?0..?9 do
    { n, << m, rest :: binary >> }
  end

  defp consume_fractional(n, power, << m, rest :: binary >>) when m in ?0..?9 do
    consume_fractional(n + (m - ?0) / power, power * 10, rest)
  end

  defp consume_fractional(n, _, "") do
    { n, "" }
  end

  defp consume_fractional(n, _, << m, rest :: binary >>) when not m in ?0..?9 do
    { n, << m, rest :: binary >> }
  end

  # String Parsing

  defp consume_string(<< ?\\, c, rest :: binary >>, acc) do
    c = case c do
      ?f -> "\f"
      ?n -> "\n"
      ?r -> "\r"
      ?t -> "\t"
      ?u ->
        { char, rest } = consume_unicode_escape(rest)
        char
      _  -> c
    end
    consume_string rest, [ c | acc ]
  end

  # Stop condition for proper end of string
  defp consume_string(<< ?", rest :: binary >>, accumulator) do
    { to_binary(Enum.reverse(accumulator)), rest }
  end

  defp consume_unicode_escape(<< a, b, c, d, rest :: binary >>) do
    s = << a, b, c, d >>
    unless JSON.Hex.is_hex?(s) do
      raise UnexpectedTokenError, token: s
    end
    { << JSON.Hex.to_integer(s) :: utf8 >>, rest }
  end

  # Never found a closing ?"
  defp consume_string(<<>>, _) do
    raise UnexpectedEndOfBufferError
  end

  defp consume_string(<< x, rest :: binary >>, accumulator) do
    consume_string(rest, [ x | accumulator ])
  end
end
