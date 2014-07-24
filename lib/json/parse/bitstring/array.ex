defmodule JSON.Parse.Bitstring.Array do
  @doc """
  Consumes a valid JSON array value, returns its elixir list representation

  ## Examples

      iex> JSON.Parse.Bitstring.Array.consume ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Bitstring.Array.consume "[1, 2 "
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Bitstring.Array.consume "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parse.Bitstring.Array.consume "[] lala"
      {:ok, [], " lala" }

      iex> JSON.Parse.Bitstring.Array.consume "[]"
      {:ok, [], "" }

      iex> JSON.Parse.Bitstring.Array.consume "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:ok, ["foo", 1, 2, 1.5], " lala" }
  """
  def consume(<< ?[, rest :: binary >>) do
    JSON.Parse.Bitstring.trim(rest) |> consume_array_contents
  end

  def consume(<< >>), do:  { :error, :unexpected_end_of_buffer }
  def consume(json),  do: { :error, { :unexpected_token, json } }


  defp consume_array_contents(json) when is_binary(json), do: consume_array_contents([], json)

  defp consume_array_contents(acc, << ?], rest :: binary >>), do: { :ok, Enum.reverse(acc), rest }
  defp consume_array_contents(_, << >>), do: { :error,  :unexpected_end_of_buffer }

  defp consume_array_contents(acc, json) do
    case JSON.Parse.Bitstring.trim(json) |> JSON.Parse.Bitstring.consume do
      { :error, error_info } -> { :error, error_info }
      {:ok, value, after_value } ->
        after_value = JSON.Parse.Bitstring.trim(after_value)
        case after_value do
          << ?, , after_comma :: binary >> ->
            consume_array_contents([value | acc], JSON.Parse.Bitstring.trim(after_comma))
          _ ->
            consume_array_contents([value | acc], after_value)
        end
    end
  end
end

