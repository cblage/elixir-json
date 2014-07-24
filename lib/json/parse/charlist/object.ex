defmodule JSON.Parse.Charlist.Object do
  @doc """
  Consumes a valid JSON object value, returns its elixir Map representation

  ## Examples

      iex> JSON.Parse.Charlist.Object.consume ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Charlist.Object.consume 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parse.Charlist.Object.consume '[] '
      {:error, {:unexpected_token, '[] '}}

      iex> JSON.Parse.Charlist.Object.consume '[]'
      {:error, {:unexpected_token, '[]'}}

      iex> JSON.Parse.Charlist.Object.consume '{"result": "this will be a elixir result"} lalal'
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), ' lalal'}
  """
  def consume([ ?{ | rest ]) do
    JSON.Parse.Charlist.trim(rest)
      |> consume_object_contents
  end

  def consume([ ]),  do: {:error, :unexpected_end_of_buffer}
  def consume(json), do: {:error, { :unexpected_token, json }}

  defp consume_object_key(json) when is_list(json) do
    case JSON.Parse.Charlist.String.consume(json) do
      { :error, error_info } -> { :error, error_info }
      { :ok, key, after_key } ->
        case JSON.Parse.Charlist.trim(after_key) do
          [ ?: | after_colon ] ->
            { :ok, key, JSON.Parse.Charlist.trim(after_colon) }
          [] ->
            { :error, :unexpected_end_of_buffer }
          _ ->
            { :error, { :unexpected_token, JSON.Parse.Charlist.trim(after_key) } }
        end
    end
  end

  defp consume_object_value(acc, key, after_key) do
    case JSON.Parse.Charlist.consume(after_key) do
      { :error, error_info} -> { :error, error_info }
      { :ok, value, after_value } ->
        acc  = Map.put(acc, key, value)
        after_value = JSON.Parse.Charlist.trim(after_value)
        case after_value do
          [ ?, | after_comma ] ->
            consume_object_contents(acc,
              JSON.Parse.Charlist.trim(after_comma))
          _ ->
            consume_object_contents(acc, after_value)
        end
    end
  end

  defp consume_object_contents(json) do
    consume_object_contents(Map.new, json)
  end

  defp consume_object_contents(acc, [ ?" | _ ] = list) do
    case consume_object_key(list) do
      { :error, error_info }  -> { :error, error_info }
      { :ok, key, after_key } -> consume_object_value(acc, key, after_key)
    end
  end

  defp consume_object_contents(acc, [ ?} | rest ]) do
    { :ok, acc, rest }
  end

  defp consume_object_contents(_, [ ]),  do: { :error, :unexpected_end_of_buffer }
  defp consume_object_contents(_, json), do: { :error, { :unexpected_token, json } }
end
