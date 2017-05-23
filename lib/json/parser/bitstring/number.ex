defmodule JSON.Parser.Bitstring.Number do

  @doc """
  parses a valid JSON numerical value, returns its elixir numerical representation

  ## Examples

      iex> JSON.Parser.Bitstring.Number.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.Number.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.Number.parse "-hello"
      {:error, {:unexpected_token, "hello"} }

      iex> JSON.Parser.Bitstring.Number.parse "129245"
      {:ok, 129245, "" }

      iex> JSON.Parser.Bitstring.Number.parse "7.something"
      {:ok, 7, ".something" }

      iex> JSON.Parser.Bitstring.Number.parse "7.4566something"
      {:ok, 7.4566, "something" }

      iex> JSON.Parser.Bitstring.Number.parse "-88.22suffix"
      {:ok, -88.22, "suffix" }

      iex> JSON.Parser.Bitstring.Number.parse "-12e4and then some"
      {:ok, -1.2e+5, "and then some" }

      iex> JSON.Parser.Bitstring.Number.parse "7842490016E-12-and more"
      {:ok, 7.842490016e-3, "-and more" }
  """
  def parse(<< ?- , rest :: binary >>) do
    case parse(rest) do
      { :ok, number, json } -> { :ok, -1 * number, json }
      { :error, error_info } -> { :error, error_info }
    end
  end

  def parse(<< number :: utf8 ,  rest:: binary >>) when number in ?0..?9 do
    << number :: utf8 ,  rest:: binary >> |> to_integer |> add_fractional |> apply_exponent
  end
  def parse(<< >>), do: { :error, :unexpected_end_of_buffer }
  def parse(json), do: { :error, { :unexpected_token, json } }

  defp add_fractional({ :error, error_info }), do: { :error, error_info }
  defp add_fractional({ :ok, acc, << ?., c :: utf8, rest :: binary >>}) when c in ?0..?9 do
   { fractional, rest } = parse_fractional(<< c :: utf8, rest :: binary >>, 0, 10.0)
   { :ok, acc + fractional, rest }
  end
  defp add_fractional(result), do: result

  defp parse_fractional(<< number :: utf8, rest :: binary >>, acc, power) when number in ?0..?9 do
    parse_fractional(rest, acc + (number - ?0) / power, power * 10)
  end

  defp parse_fractional(json, acc , _) when is_binary(json), do: { acc, json }


  defp apply_exponent({ :error, error_info }), do: { :error, error_info }

  defp apply_exponent({ :ok, acc, << exponent :: utf8, rest :: binary >> }) when exponent in 'eE' do
    case to_integer(rest) do
      { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
      { :error, error_info } -> { :error, error_info }
    end
  end

  defp apply_exponent({ :ok, acc, json }), do: { :ok, acc, json }


  defp to_integer(<< >>), do: { :error,  :unexpected_end_of_buffer }
  defp to_integer(binary) do
    case Integer.parse(binary) do
      { :error, _ } -> { :error, { :unexpected_token, binary } }
      { result, rest } -> {:ok, result, rest}
    end
  end
end