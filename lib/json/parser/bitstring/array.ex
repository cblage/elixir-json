defmodule JSON.Parser.Bitstring.Array do
  @doc """
  parses a valid JSON array value, returns its elixir list representation

  ## Examples

      iex> JSON.Parser.Bitstring.Array.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.Array.parse "[1, 2 "
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.Array.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.Array.parse "[] lala"
      {:ok, [], " lala" }

      iex> JSON.Parser.Bitstring.Array.parse "[]"
      {:ok, [], "" }

      iex> JSON.Parser.Bitstring.Array.parse "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:ok, ["foo", 1, 2, 1.5], " lala" }
  """
  def parse(<< ?[, rest :: binary >>) do
    JSON.Parser.Bitstring.trim(rest) |> parse_array_contents
  end

  def parse(<< >>), do:  { :error, :unexpected_end_of_buffer }
  def parse(json),  do: { :error, { :unexpected_token, json } }


  defp parse_array_contents(json) when is_binary(json), do: parse_array_contents([], json)

  defp parse_array_contents(acc, << ?], rest :: binary >>), do: { :ok, Enum.reverse(acc), rest }
  defp parse_array_contents(_, << >>), do: { :error,  :unexpected_end_of_buffer }

  defp parse_array_contents(acc, json) do
    case JSON.Parser.Bitstring.trim(json) |> JSON.Parser.Bitstring.parse do
      { :error, error_info } -> { :error, error_info }
      {:ok, value, after_value } ->
        after_value = JSON.Parser.Bitstring.trim(after_value)
        case after_value do
          << ?, , after_comma :: binary >> ->
            parse_array_contents([value | acc], JSON.Parser.Bitstring.trim(after_comma))
          _ ->
            parse_array_contents([value | acc], after_value)
        end
    end
  end
end

