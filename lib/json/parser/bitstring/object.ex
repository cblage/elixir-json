defmodule JSON.Parser.Bitstring.Object do
  @doc """
  parses a valid JSON object value, returns its elixir representation

  ## Examples

      iex> JSON.Parser.Bitstring.Object.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.Object.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.Object.parse "[] "
      {:error, {:unexpected_token, "[] "}}

      iex> JSON.Parser.Bitstring.Object.parse "[]"
      {:error, {:unexpected_token, "[]"}}

      iex> JSON.Parser.Bitstring.Object.parse "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:error, {:unexpected_token, "[\\\"foo\\\", 1, 2, 1.5] lala"}}

      iex> JSON.Parser.Bitstring.Object.parse "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), " lalal"}
  """
  def parse(<< ?{, rest :: binary >>) do
    JSON.Parser.Bitstring.trim(rest)
      |> parse_object_contents
  end

  def parse(<< >>), do: { :error, :unexpected_end_of_buffer }
  def parse(json),  do: { :error, { :unexpected_token, json } }

  # Object Parsing
  defp parse_object_key(json) do
    case JSON.Parser.Bitstring.String.parse(json) do
      {:error, error_info} -> {:error, error_info}
      {:ok, key, after_key } ->
        case JSON.Parser.Bitstring.trim(after_key) do
          << ?:,  after_colon :: binary >> ->
            { :ok, key, JSON.Parser.Bitstring.trim(after_colon) }
          << >> ->
            { :error, :unexpected_end_of_buffer}
          _ ->
            { :error, { :unexpected_token, JSON.Parser.Bitstring.trim(after_key) } }
        end
    end
  end

  defp parse_object_value(acc, key, after_key) do
    case JSON.Parser.Bitstring.parse(after_key) do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, after_value } ->
        acc = Map.put(acc, key, value)
        after_value = JSON.Parser.Bitstring.trim(after_value)
        case after_value do
          << ?,, after_comma :: binary >> ->
            parse_object_contents acc, JSON.Parser.Bitstring.trim(after_comma)
          _  ->
            parse_object_contents acc, after_value
        end
    end
  end

  defp parse_object_contents(json), do: parse_object_contents(Map.new, json)

  defp parse_object_contents(acc, << ?", _ :: binary >> = bin) do
    case parse_object_key(bin) do
      { :error, error_info }  -> { :error, error_info }
      { :ok, key, after_key } -> parse_object_value(acc, key, after_key)
    end
  end

  defp parse_object_contents(acc, << ?}, rest :: binary >>), do: { :ok, acc, rest }

  defp parse_object_contents(_, << >>), do: { :error, :unexpected_end_of_buffer }
  defp parse_object_contents(_, json), do: { :error, { :unexpected_token, json } }
end
