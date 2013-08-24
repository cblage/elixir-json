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
      {129245, "" }

      iex> JSON.Numeric.to_numeric "7.something"
      {7, ".something" }

      iex> JSON.Numeric.to_numeric "-88.22suffix"
      {-88.22, "suffix" }

      iex> JSON.Numeric.to_numeric "-12e4and then some"
      {-1.2e+5, "and then some" }

      iex> JSON.Numeric.to_numeric "7842490016E-12-and more"
      {7.842490016e-3, "-and more" }
  """
  def to_numeric(<< ?-, after_minus :: binary >>), do: to_numeric(after_minus) |> negate
  def to_numeric(string) when is_binary(string), do: String.to_integer(string) |> add_fractional |> apply_exponent
  
  defp negate(:error), do: :error
  defp negate({ number, string }) when is_binary(string), do: { -1 * number, string }

  defp add_fractional(:error), do: :error

  defp add_fractional({ sum, << ?., c, string :: binary >> }) when c in ?0..?9 do
    { fractional, string } = consume_fractional({ 0, << c, string :: binary >> }, 10.0)
    { sum + fractional, string }
  end

  # ensures the following behavior - JSON.Numeric.to_integer_from_hex "C2freezing" { 3119, "reezing" }
  defp add_fractional({ sum, string }) when is_binary(string), do: { sum, string }
  

  defp consume_fractional({ sum, << next_char, rest :: binary >> }, power) when next_char in ?0..?9 do
    consume_fractional({ sum + (next_char - ?0) / power, rest }, power * 10)
  end

  # ensures the following behavior - JSON.Numeric.to_integer_from_hex "C2freezing" { 3119, "reezing" }
  defp consume_fractional({ sum, string }, _) when is_binary(string), do: { sum, string }
  

  defp apply_exponent(:error), do: :error
  
  defp apply_exponent({ sum, << e, string :: binary >> }) when e in [?e, ?E] do
    case String.to_integer(string) do
      { power, string } -> { sum * :math.pow(10, power), string }
      _ -> :error
    end
  end

  # ensures the following behavior - JSON.Numeric.to_integer_from_hex "C2freezing" { 3119, "reezing" }
  defp apply_exponent({ sum, string }) when is_binary(string), do: { sum, string }

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
  def to_integer_from_hex(string) when is_binary(string) do
    if Regex.match?(%r{^[0-9a-fA-F]}, string) do
      to_integer_from_hex_recursive(string, 0)
    else
      :error
    end
  end

  defp to_integer_from_hex_recursive(string, sum) when is_binary(string) do
    case string do 
      << c, rest :: binary >> when c in ?0..?9 -> to_integer_from_hex_recursive(rest, 16 * sum + c - ?0)
      << c, rest :: binary >> when c in ?a..?f -> to_integer_from_hex_recursive(rest, 16 * sum + 10 + c - ?a)
      << c, rest :: binary >> when c in ?A..?F -> to_integer_from_hex_recursive(rest, 16 * sum + 10 + c - ?A)
      _ -> { sum, string }
    end
  end

end
