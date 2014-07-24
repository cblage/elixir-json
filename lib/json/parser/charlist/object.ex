defmodule JSON.Parser.Charlist.Object do
  @doc """
  parses a valid JSON object value, returns its elixir Map representation

  ## Examples

      iex> JSON.Parser.Charlist.Object.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Charlist.Object.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parser.Charlist.Object.parse '[] '
      {:error, {:unexpected_token, '[] '}}

      iex> JSON.Parser.Charlist.Object.parse '[]'
      {:error, {:unexpected_token, '[]'}}

      iex> JSON.Parser.Charlist.Object.parse '{"result": "this will be a elixir result"} lalal'
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), ' lalal'}
  """
  def parse([ ?{ | rest ]) do
    JSON.Parser.Charlist.trim(rest)
      |> parse_object_contents
  end

  def parse([ ]),  do: {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, { :unexpected_token, json }}

  defp parse_object_key(json) when is_list(json) do
    case JSON.Parser.Charlist.String.parse(json) do
      { :error, error_info } -> { :error, error_info }
      { :ok, key, after_key } ->
        case JSON.Parser.Charlist.trim(after_key) do
          [ ?: | after_colon ] ->
            { :ok, key, JSON.Parser.Charlist.trim(after_colon) }
          [] ->
            { :error, :unexpected_end_of_buffer }
          _ ->
            { :error, { :unexpected_token, JSON.Parser.Charlist.trim(after_key) } }
        end
    end
  end

  defp parse_object_value(acc, key, after_key) do
    case JSON.Parser.Charlist.parse(after_key) do
      { :error, error_info} -> { :error, error_info }
      { :ok, value, after_value } ->
        acc  = Map.put(acc, key, value)
        after_value = JSON.Parser.Charlist.trim(after_value)
        case after_value do
          [ ?, | after_comma ] ->
            parse_object_contents(acc,
              JSON.Parser.Charlist.trim(after_comma))
          _ ->
            parse_object_contents(acc, after_value)
        end
    end
  end

  defp parse_object_contents(json) do
    parse_object_contents(Map.new, json)
  end

  defp parse_object_contents(acc, [ ?" | _ ] = list) do
    case parse_object_key(list) do
      { :error, error_info }  -> { :error, error_info }
      { :ok, key, after_key } -> parse_object_value(acc, key, after_key)
    end
  end

  defp parse_object_contents(acc, [ ?} | rest ]) do
    { :ok, acc, rest }
  end

  defp parse_object_contents(_, [ ]),  do: { :error, :unexpected_end_of_buffer }
  defp parse_object_contents(_, json), do: { :error, { :unexpected_token, json } }
end
