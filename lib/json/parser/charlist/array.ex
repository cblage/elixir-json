defmodule JSON.Parser.Charlist.Array do
  @moduledoc """
  Implements a JSON Array Parser for Charlist values
  """

  alias JSON.Parser.Charlist, as: CharlistParser
  import CharlistParser, only: [trim: 1]

  @doc """
  parses a valid JSON array value, returns its elixir list representation

  ## Examples

      iex> JSON.Parser.Charlist.Array.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Charlist.Array.parse '[1, 2 '
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Charlist.Array.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'}}

      iex> JSON.Parser.Charlist.Array.parse '[] lala'
      {:ok, [], ' lala'}

      iex> JSON.Parser.Charlist.Array.parse '[]'
      {:ok, [], ''}

      iex> JSON.Parser.Charlist.Array.parse '["foo", 1, 2, 1.5] lala'
      {:ok, ["foo", 1, 2, 1.5], ' lala'}
  """
  def parse([?[| rest]) do
    rest |> trim |> parse_array_contents
  end

  def parse([]),  do: {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, {:unexpected_token, json}}

  # Array Parsing
  defp parse_array_contents(json) when is_list(json) do
    parse_array_contents([], json)
  end

  defp parse_array_contents(acc, [?] | rest]) do
      {:ok, Enum.reverse(acc), rest}
  end

  defp parse_array_contents(_, []), do: {:error, :unexpected_end_of_buffer}

  defp parse_array_contents(acc, json) do
    case json
          |> trim
          |> CharlistParser.parse
    do
      {:error, error_info} -> {:error, error_info}
      {:ok, value, after_value} ->
        trimmed_after_value = trim(after_value)
        case trimmed_after_value do
          [?, | after_comma] ->
            parse_array_contents([value | acc], trim(after_comma))
          _ ->
            parse_array_contents([value | acc], trimmed_after_value)
        end
    end
  end
end
