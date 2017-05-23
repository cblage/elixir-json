defmodule JSON.Parser.Bitstring.String do

  use Bitwise
  @doc """
  parses a valid JSON string, returns its elixir representation

  ## Examples

      iex> JSON.Parser.Bitstring.String.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.String.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.String.parse "-hello"
      {:error, {:unexpected_token, "-hello"} }

      iex> JSON.Parser.Bitstring.String.parse "129245"
      {:error, {:unexpected_token, "129245"} }

      iex> JSON.Parser.Bitstring.String.parse "\\\"7.something\\\""
      {:ok, "7.something", "" }

      iex> JSON.Parser.Bitstring.String.parse "\\\"-88.22suffix\\\" foo bar"
      {:ok, "-88.22suffix", " foo bar" }

      iex> JSON.Parser.Bitstring.String.parse "\\\"star -> \\\\u272d <- star\\\""
      {:ok, "star -> ✭ <- star", "" }

      iex> JSON.Parser.Bitstring.String.parse "\\\"\\\\u00df ist wunderbar\\\""
      {:ok, "ß ist wunderbar", "" }

      iex> JSON.Parser.Bitstring.String.parse "\\\"Rafaëlla\\\" foo bar"
      {:ok, "Rafaëlla", " foo bar" }

      iex> JSON.Parser.Bitstring.String.parse "\\\"Éloise woot\\\" Éloise"
      {:ok, "Éloise woot", " Éloise" }
  """
  def parse(<< ?" :: utf8 , json :: binary >>), do: parse_string_recursive(json, [ ])
  def parse(<< >>), do: { :error, :unexpected_end_of_buffer }
  def parse(json), do: { :error, { :unexpected_token, json } }


  #stop conditions
  defp parse_string_recursive(<< >>, _), do: { :error, :unexpected_end_of_buffer }

  # found the closing ", lets reverse the acc and encode it as a string!
  defp parse_string_recursive(<< ?" :: utf8, json :: binary >>, acc) do
    case acc |> Enum.reverse |> List.to_string do
      encoded when is_binary(encoded) ->
        { :ok, encoded, json }
      _ ->
        {:error, { :unexpected_token, json }}
    end
  end

  #parsing
  defp parse_string_recursive(<< ?\\, ?f,  json :: binary >>, acc) do
    parse_string_recursive(json, [ ?\f | acc ])
  end
  defp parse_string_recursive(<< ?\\, ?n,  json :: binary >>, acc) do
    parse_string_recursive(json, [ ?\n | acc ])
  end
  defp parse_string_recursive(<< ?\\, ?r,  json :: binary >>, acc) do
    parse_string_recursive(json, [ ?\r | acc ])
  end
  defp parse_string_recursive(<< ?\\, ?t,  json :: binary >>, acc) do
    parse_string_recursive(json, [ ?\t | acc ])
  end
  defp parse_string_recursive(<< ?\\, ?",  json :: binary >>, acc)  do
    parse_string_recursive(json, [ ?"  | acc ])
  end
  defp parse_string_recursive(<< ?\\, ?\\, json :: binary >>, acc)  do
    parse_string_recursive(json, [ ?\\ | acc ])
  end
  defp parse_string_recursive(<< ?\\, ?/,  json :: binary >>, acc) do
    parse_string_recursive(json, [ ?/  | acc ])
  end

  defp parse_string_recursive(<< ?\\, ?u , json :: binary >>, acc) do
    case JSON.Parser.Bitstring.Unicode.parse(<< ?\\, ?u , json :: binary >>) do
      { :error, error_info } -> { :error, error_info }
      { :ok, decoded_unicode_codepoint, after_codepoint} ->
        case decoded_unicode_codepoint do
          << _ ::utf8 >> ->
            parse_string_recursive(after_codepoint, [ decoded_unicode_codepoint | acc ])
          _ ->
            { :error, { :unexpected_token, << ?\\, ?u , json :: binary >>} }
        end
    end
  end

  defp parse_string_recursive(<< char :: utf8, json :: binary >>, acc) do
    parse_string_recursive(json, [ char | acc ])
  end

end
