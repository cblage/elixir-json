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

  def consume_value("{}") do
    { HashDict.new, "" }
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

  defp consume_fractional(n, power, "") do
    { n, "" }
  end

  defp consume_fractional(n, power, << m, rest :: binary >>) when not m in ?0..?9 do
    { n, rest }
  end

  #Accepts anything considered a root token (object or array for now)
  defp accept_root(bitstring) do
    {root, remaining_bitstring} = String.lstrip(bitstring) |> process_root_token

    #remaining_bitstring should be empty due to being in the root context otherwise this is invalid json
    unless "" === String.strip(remaining_bitstring) do
      raise UnexpectedTokenError, token: remaining_bitstring
    end

    root
  end

  defp process_root_token(<< ?{ , tail :: binary >>) do
    accept_object(tail)
  end

  defp process_root_token(<< ?[ , tail :: binary >>) do
    accept_list(tail)
  end

  defp process_root_token(token) when is_bitstring(token) do
    raise UnexpectedTokenError, token: token
  end

  defp accept_object(bitstring) when is_bitstring(bitstring) do
    raise "not implemented"
  end

  defp accept_list(bitstring) when is_bitstring(bitstring) do
    raise "not implemented"
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
end
