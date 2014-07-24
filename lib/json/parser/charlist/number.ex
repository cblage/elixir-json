defmodule JSON.Parser.Charlist.Number do
  @doc """
  parses a valid JSON numerical value, returns its elixir numerical representation

  ## Examples

      iex> JSON.Parser.Charlist.Number.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Charlist.Number.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parser.Charlist.Number.parse '-hello'
      {:error, {:unexpected_token, 'hello'} }

      iex> JSON.Parser.Charlist.Number.parse '129245'
      {:ok, 129245, '' }

      iex> JSON.Parser.Charlist.Number.parse '7.something'
      {:ok, 7, '.something' }

      iex> JSON.Parser.Charlist.Number.parse '7.4566something'
      {:ok, 7.4566, 'something' }

      iex> JSON.Parser.Charlist.Number.parse '-88.22suffix'
      {:ok, -88.22, 'suffix' }

      iex> JSON.Parser.Charlist.Number.parse '-12e4and then some'
      {:ok, -1.2e+5, 'and then some' }

      iex> JSON.Parser.Charlist.Number.parse '7842490016E-12-and more'
      {:ok, 7.842490016e-3, '-and more' }
  """
  def parse([ ?- | rest]) do
    case parse(rest) do
      { :ok, number, json } ->  { :ok, -1 * number, json }
      { :error, error_info } -> { :error, error_info }
    end
  end

  def parse(charlist) when is_list(charlist) do
    case charlist do
      [ number | _ ] when number in ?0..?9 ->
          to_integer(charlist) |> add_fractional |> apply_exponent
      [ ] ->
        { :error, :unexpected_end_of_buffer }
      _  ->
        { :error, { :unexpected_token, charlist } }
    end
  end

  # mini-wrapper around :string.to_integer
  defp to_integer([ ]), do: { :error, :unexpected_end_of_buffer }

  defp to_integer(charlist) when is_list(charlist) do
    case :string.to_integer(charlist) do
      { :error, _ } -> { :error, { :unexpected_token, charlist } }
      { result, rest } -> { :ok, result, rest }
    end
  end

  #fractional
  defp add_fractional({ :error, error_info }), do: { :error, error_info }

  defp add_fractional({:ok, acc, [ ?. | after_dot ] }) do
    case after_dot do
      [ c | _ ] when c in ?0..?9  ->
        { fractional, after_fractional } = parse_fractional(after_dot, 0, 10.0)
        { :ok, acc + fractional, after_fractional }
      _ ->
        { :ok, acc, [ ?. | after_dot ] }
    end
  end

  defp add_fractional({ :ok, acc, json }), do: { :ok, acc, json }

  defp parse_fractional([ number | rest ], acc, power) when number in ?0..?9 do
    parse_fractional(rest, acc + (number - ?0) / power, power * 10)
  end

  defp parse_fractional(json, acc , _), do: { acc, json }


  #exponent
  defp apply_exponent({ :error, error_info }), do: { :error, error_info }

  defp apply_exponent({ :ok, acc, [ exponent | rest ] }) when exponent in 'eE' do
    case to_integer(rest) do
      { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
      { :error, error_info } -> { :error, error_info }
    end
  end

  defp apply_exponent({ :ok, acc, json }), do: { :ok, acc, json }
end
