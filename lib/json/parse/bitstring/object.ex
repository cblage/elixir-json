defmodule JSON.Parse.Bitstring.Object do
  @doc """
  Consumes a valid JSON object value, returns its elixir representation

  ## Examples

      iex> JSON.Parse.Bitstring.Object.consume ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Bitstring.Object.consume "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parse.Bitstring.Object.consume "[] "
      {:error, {:unexpected_token, "[] "}}

      iex> JSON.Parse.Bitstring.Object.consume "[]"
      {:error, {:unexpected_token, "[]"}}

      iex> JSON.Parse.Bitstring.Object.consume "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:error, {:unexpected_token, "[\\\"foo\\\", 1, 2, 1.5] lala"}}

      iex> JSON.Parse.Bitstring.Object.consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), " lalal"}
  """
  def consume(<< ?{, rest :: binary >>) do
    JSON.Parse.Bitstring.trim(rest)
      |> consume_object_contents
  end

  def consume(<< >>), do: { :error, :unexpected_end_of_buffer }
  def consume(json),  do: { :error, { :unexpected_token, json } }

  # Object Parsing
  defp consume_object_key(json) do
    case JSON.Parse.Bitstring.String.consume(json) do
      {:error, error_info} -> {:error, error_info}
      {:ok, key, after_key } ->
        case JSON.Parse.Bitstring.trim(after_key) do
          << ?:,  after_colon :: binary >> ->
            { :ok, key, JSON.Parse.Bitstring.trim(after_colon) }
          << >> ->
            { :error, :unexpected_end_of_buffer}
          _ ->
            { :error, { :unexpected_token, JSON.Parse.Bitstring.trim(after_key) } }
        end
    end
  end

  defp consume_object_value(acc, key, after_key) do
    case JSON.Parse.Bitstring.consume(after_key) do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, after_value } ->
        acc = Map.put(acc, key, value)
        after_value = JSON.Parse.Bitstring.trim(after_value)
        case after_value do
          << ?,, after_comma :: binary >> ->
            consume_object_contents acc, JSON.Parse.Bitstring.trim(after_comma)
          _  ->
            consume_object_contents acc, after_value
        end
    end
  end

  defp consume_object_contents(json), do: consume_object_contents(Map.new, json)

  defp consume_object_contents(acc, << ?", _ :: binary >> = bin) do
    case consume_object_key(bin) do
      { :error, error_info }  -> { :error, error_info }
      { :ok, key, after_key } -> consume_object_value(acc, key, after_key)
    end
  end

  defp consume_object_contents(acc, << ?}, rest :: binary >>), do: { :ok, acc, rest }

  defp consume_object_contents(_, << >>), do: { :error, :unexpected_end_of_buffer }
  defp consume_object_contents(_, json), do: { :error, { :unexpected_token, json } }
end
