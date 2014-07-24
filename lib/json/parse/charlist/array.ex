defmodule JSON.Parse.Charlist.Array do
  @doc """
  Consumes a valid JSON array value, returns its elixir list representation

  ## Examples

      iex> JSON.Parse.Charlist.Array.consume ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Charlist.Array.consume '[1, 2 '
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Charlist.Array.consume 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parse.Charlist.Array.consume '[] lala'
      {:ok, [], ' lala' }

      iex> JSON.Parse.Charlist.Array.consume '[]'
      {:ok, [], '' }

      iex> JSON.Parse.Charlist.Array.consume '["foo", 1, 2, 1.5] lala'
      {:ok, ["foo", 1, 2, 1.5], ' lala' }
  """
  def consume([ ?[ | rest ]) do
    JSON.Parse.Charlist.trim(rest) |> consume_array_contents
  end

  def consume([ ]),  do: { :error, :unexpected_end_of_buffer }
  def consume(json), do: { :error, { :unexpected_token, json } }


  # Array Parsing

  defp consume_array_contents(json) when is_list(json) do
    consume_array_contents([], json)
  end

  defp consume_array_contents(acc, [ ?] | rest ]) do
      {:ok, Enum.reverse(acc), rest }
  end

  defp consume_array_contents(_, [ ]), do: { :error, :unexpected_end_of_buffer }

  defp consume_array_contents(acc, json) do
    case JSON.Parse.Charlist.trim(json)
            |> JSON.Parse.Charlist.consume
    do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, after_value } ->
        after_value = JSON.Parse.Charlist.trim(after_value)
        case after_value  do
          [ ?, | after_comma ] ->
            consume_array_contents([value | acc], JSON.Parse.Charlist.trim(after_comma))
          _ ->
            consume_array_contents([value | acc], after_value)
        end
    end
  end
end

