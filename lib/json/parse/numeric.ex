defmodule JSON.Parse.Numeric do

  @doc """
  Like a mix of `String.to_integer` and `String.to_float`, but with some
  JSON-specific rules.

  Examples

      iex> JSON.Parse.Numeric.to_numeric ""
      :error

      iex> JSON.Parse.Numeric.to_numeric "face0ff"
      :error

      iex> JSON.Parse.Numeric.to_numeric "-hello"
      :error

      iex> JSON.Parse.Numeric.to_numeric "129245"
      {129245, "" }

      iex> JSON.Parse.Numeric.to_numeric "7.something"
      {7, ".something" }

      iex> JSON.Parse.Numeric.to_numeric "-88.22suffix"
      {-88.22, "suffix" }

      iex> JSON.Parse.Numeric.to_numeric "-12e4and then some"
      {-1.2e+5, "and then some" }

      iex> JSON.Parse.Numeric.to_numeric "7842490016E-12-and more"
      {7.842490016e-3, "-and more" }
  """
  def iolist_to_integer(iolist) when is_list(iolist) do
    {result, remainder} = :string.to_integer(iolist)
    case result do
      :error -> :error
      _ -> {result, remainder}
    end
  end

  def to_numeric(bitstring) when is_binary(bitstring) do
    case bitstring_to_list(bitstring) |> to_numeric do
      { result, rest } -> {result, iolist_to_binary(rest)}
      :error -> :error
    end
  end

  def to_numeric([?- | after_minus ]), do: to_numeric(after_minus) |> negate
  def to_numeric(iolist) when is_list(iolist), do: iolist_to_integer(iolist) |> add_fractional |> apply_exponent
  
  defp negate(:error), do: :error
  defp negate({ number, iolist }) when is_list(iolist), do: { -1 * number, iolist }

  defp add_fractional(:error), do: :error

  defp add_fractional({ sum, [ ?., c | iolist ] }) when c in ?0..?9 do
    { fractional, string } = consume_fractional({ 0, [ c | iolist ] }, 10.0)
    { sum + fractional, string }
  end

  # ensures the following behavior - JSON.Parse.Numeric.to_integer_from_hex "C2freezing" { 3119, "reezing" }
  defp add_fractional({ sum, iolist }) when is_list(iolist), do: { sum, iolist }
  

  defp consume_fractional({ sum, [ next_char | rest ] }, power) when next_char in ?0..?9 do
    consume_fractional({ sum + (next_char - ?0) / power, rest }, power * 10)
  end

  # ensures the following behavior - JSON.Parse.Numeric.to_integer_from_hex "C2freezing" { 3119, "reezing" }
  defp consume_fractional({ sum, iolist }, _) when is_list(iolist), do: { sum, iolist }
  

  defp apply_exponent(:error), do: :error
  
  defp apply_exponent({ sum, [ e | rest ] }) when e in [?e, ?E] do
    case iolist_to_integer(rest) do
      { power, rest } -> { sum * :math.pow(10, power), rest }
      _ -> :error
    end
  end

  # ensures the following behavior - JSON.Parse.Numeric.to_integer_from_hex "C2freezing" { 3119, "reezing" }
  defp apply_exponent({ sum, iolist }) when is_list(iolist), do: { sum, iolist }

  @doc """
  Like `String.to_integer`, but for hexadecimal numbers.

  Examples

      iex> JSON.Parse.Numeric.to_integer_from_hex ""
      :error

      iex> JSON.Parse.Numeric.to_integer_from_hex "xkcd"
      :error

      iex> JSON.Parse.Numeric.to_integer_from_hex "94"
      { 148, "" }

      iex> JSON.Parse.Numeric.to_integer_from_hex "C2freezing"
      { 3119, "reezing" }
  """
  def to_integer_from_hex(bitstring) when is_binary(bitstring) do
    case bitstring_to_list(bitstring) |> to_integer_from_hex do
      { result, rest } -> {result, iolist_to_binary(rest)}
      :error -> :error
    end   
  end

  def to_integer_from_hex(iolist) when is_list(iolist) do
    if Regex.match?(%r{^[0-9a-fA-F]}, iolist) do
      to_integer_from_hex_recursive(iolist, 0)
    else
      :error
    end
  end


  defp to_integer_from_hex_recursive(iolist, sum) when is_list(iolist) do
    case iolist do 
      [ c | rest ] when c in ?0..?9 -> to_integer_from_hex_recursive(rest, 16 * sum + c - ?0)
      [ c | rest ] when c in ?a..?f -> to_integer_from_hex_recursive(rest, 16 * sum + 10 + c - ?a)
      [ c | rest ] when c in ?A..?F -> to_integer_from_hex_recursive(rest, 16 * sum + 10 + c - ?A)
      _ -> { sum, iolist }
    end
  end

end
