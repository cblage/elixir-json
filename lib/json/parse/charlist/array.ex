defmodule JSON.Parse.Charlist.Array do
  @doc """
  parses a valid JSON array value, returns its elixir list representation

  ## Examples

      iex> JSON.Parse.Charlist.Array.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Charlist.Array.parse '[1, 2 '
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Charlist.Array.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parse.Charlist.Array.parse '[] lala'
      {:ok, [], ' lala' }

      iex> JSON.Parse.Charlist.Array.parse '[]'
      {:ok, [], '' }

      iex> JSON.Parse.Charlist.Array.parse '["foo", 1, 2, 1.5] lala'
      {:ok, ["foo", 1, 2, 1.5], ' lala' }
  """
  def parse([ ?[ | rest ]) do
    JSON.Parse.Charlist.trim(rest) |> parse_array_contents
  end

  def parse([ ]),  do: { :error, :unexpected_end_of_buffer }
  def parse(json), do: { :error, { :unexpected_token, json } }


  # Array Parsing

  defp parse_array_contents(json) when is_list(json) do
    parse_array_contents([], json)
  end

  defp parse_array_contents(acc, [ ?] | rest ]) do
      {:ok, Enum.reverse(acc), rest }
  end

  defp parse_array_contents(_, [ ]), do: { :error, :unexpected_end_of_buffer }

  defp parse_array_contents(acc, json) do
    case JSON.Parse.Charlist.trim(json)
            |> JSON.Parse.Charlist.parse
    do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, after_value } ->
        after_value = JSON.Parse.Charlist.trim(after_value)
        case after_value  do
          [ ?, | after_comma ] ->
            parse_array_contents([value | acc], JSON.Parse.Charlist.trim(after_comma))
          _ ->
            parse_array_contents([value | acc], after_value)
        end
    end
  end
end

