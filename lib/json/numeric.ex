defmodule JSON.Numeric do

  @doc """
  Like a mix of `String.to_integer` and `String.to_float`, but with some
  JSON-specific rules.

  Examples

      iex> JSON.Numeric.to_numeric ""
      :error

      iex> JSON.Numeric.to_numeric "face0ff"
      :error

      iex> JSON.Numeric.to_numeric "-hello"
      :error

      iex> JSON.Numeric.to_numeric "129245"
      { 129245, "" }

      iex> JSON.Numeric.to_numeric "-88.22suffix"
      { -88.22, "suffix" }
  """
  def to_numeric(string) do
    case string do
      << ?-, string :: binary >> ->
        to_numeric(string) |> negate
      << char, string :: binary >> when char in ?0..?9 ->
        to_numeric to_i(char), string
      _ ->
        :error
    end
  end

  defp negate(:error), do: :error
  defp negate({ number, string }), do: { -1 * number, string }

  defp to_i(char) when char in ?0..?9, do: char - ?0

  defp to_numeric sum, string do
    case string do
      << char, string :: binary >> when char in ?0..?9 ->
        to_numeric sum * 10 + to_i(char), string
      << ?., string :: binary >> ->
        { fractional, string } = consume_fractional({ 0, string }, 10.0)
        { sum + fractional, string }
      _ ->
        { sum, string }
    end
  end

  defp consume_fractional { number, "" }, _ do
    { number, "" }
  end

  defp consume_fractional { n, << next_char, rest :: binary >> }, power do
    case next_char do
      m when m in ?0..?9 ->
        consume_fractional { n + (next_char - ?0) / power, rest }, power * 10
      _ ->
        { n, << next_char, rest :: binary >> }
    end
  end

  @doc """
  Like `String.to_integer`, but for hexadecimal numbers.

  Examples

      iex> JSON.Numeric.to_integer_from_hex ""
      :error

      iex> JSON.Numeric.to_integer_from_hex "xkcd"
      :error

      iex> JSON.Numeric.to_integer_from_hex "94"
      { 148, "" }

      iex> JSON.Numeric.to_integer_from_hex "C2freezing"
      { 3119, "reezing" }
  """
  def to_integer_from_hex(s) do
    case Regex.match?(%r{^[0-9a-fA-F]}, s) do
      true -> to_integer_from_hex(s, 0)
      false -> :error
    end
  end

  defp to_integer_from_hex(s, sum) do
    case s do
      << c, rest :: binary >> when c in ?0..?9 ->
        to_integer_from_hex rest, 16 * sum + c - ?0
      << c, rest :: binary >> when c in ?a..?f ->
        to_integer_from_hex rest, 16 * sum + 10 + c - ?a
      << c, rest :: binary >> when c in ?A..?F ->
        to_integer_from_hex rest, 16 * sum + 10 + c - ?A
      _ ->
        { sum, s }
    end
  end

end
