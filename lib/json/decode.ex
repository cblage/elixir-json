defmodule JSON.Decode do
  defexception UnexpectedTokenError, token: nil do
    def message(exception) do
      "Invalid JSON - unexpected token >>#{exception.token}<<"
    end
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"

  def from_json(s) when is_binary(s) do
    { result, rest } = consume_value(String.lstrip(s))
    unless "" == String.rstrip(rest) do
      raise UnexpectedTokenError, token: rest
    end
    result
  end

  def consume_value("null"  <> rest), do: { nil,   rest }
  def consume_value("true"  <> rest), do: { true,  rest }
  def consume_value("false" <> rest), do: { false, rest }

  # Array Parsing

  def consume_value(<< ?[, rest :: binary >>) do
    consume_array_contents(String.lstrip(rest), [])
  end

  defp consume_array_contents(<< ?], after_close :: binary >>, acc) do
    { Enum.reverse(acc), after_close }
  end

  defp consume_array_contents(json, acc) do
    { value, after_value } = consume_value(String.lstrip(json))
    acc = [ value | acc ]
    after_value = String.lstrip(after_value)

    case after_value do
      << ?,, after_comma :: binary >> ->
        after_comma = String.lstrip(after_comma)
        consume_array_contents(after_comma, acc)
      << ?], after_close :: binary >> ->
        { Enum.reverse(acc), after_close }
    end
  end

  # Object Parsing

  def consume_value(<< ?{, rest :: binary >>) do
    consume_object_contents(String.lstrip(rest), HashDict.new)
  end

  defp consume_object_contents(<< ?}, rest :: binary >>, acc) do
    { acc, rest }
  end

  defp consume_object_contents(<< ?", rest :: binary >>, acc) do
    { key, rest } = consume_string(rest, [])

    case String.lstrip(rest) do
      << ?:, rest :: binary >> ->
        rest = String.lstrip(rest)
      <<>> ->
        raise UnexpectedEndOfBufferError
      _ ->
        raise UnexpectedTokenError, token: rest
    end

    { value, rest } = consume_value(rest)
    acc = HashDict.put(acc, key, value)
    rest = String.lstrip(rest)

    case rest do
      << ?,, rest :: binary >> ->
        rest = String.lstrip(rest)
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

  def consume_value(<< ?", rest :: binary >>) do
    consume_string(rest, [])
  end

  # Number Parsing

  def consume_value(<< ?-, m, rest :: binary >>) when m in ?0..?9 do
    { number, tail } = consume_number(m - ?0, rest)
    { -1 * number, tail }
  end

  def consume_value(<< m, rest :: binary >>) when m in ?0..?9 do
    consume_number m - ?0, rest
  end

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
    { n, rest }
  end

  # String Parsing

  # Stop condition for proper end of string
  defp consume_string(<< ?", rest :: binary >>, accumulator) do
    { to_binary(Enum.reverse(accumulator)), rest }
  end

  # Never found a closing ?"
  defp consume_string(<<>>, _) do
    raise UnexpectedEndOfBufferError
  end

  defp consume_string(<< x, rest :: binary >>, accumulator) do
    consume_string(rest, [ x | accumulator ])
  end

  def consume_value(s) do
    if String.length(s) == 0 do
      raise UnexpectedEndOfBufferError
    end

    raise UnexpectedTokenError, token: s
  end
end
