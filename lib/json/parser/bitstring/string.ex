defmodule JSON.Parser.Bitstring.String do
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
  def parse(<< ?" :: utf8 , json :: binary >>), do: parse_string_contents(json, [ ])
  def parse(<< >>), do: { :error, :unexpected_end_of_buffer }
  def parse(json), do: { :error, { :unexpected_token, json } }


  #stop conditions
  defp parse_string_contents(<< >>, _), do: { :error, :unexpected_end_of_buffer }

  # found the closing ", lets reverse the acc and encode it as a string!
  defp parse_string_contents(<< ?" :: utf8, json :: binary >>, acc) do
    case Enum.reverse(acc) |> List.to_string do
      encoded when is_binary(encoded) ->
        { :ok, encoded, json }
      _ ->
        {:error, { :unexpected_token, json }}
    end
  end

  #parsing
  defp parse_string_contents(<< ?\\, ?f,  json :: binary >>, acc), do: parse_string_contents(json, [ ?\f | acc ])
  defp parse_string_contents(<< ?\\, ?n,  json :: binary >>, acc), do: parse_string_contents(json, [ ?\n | acc ])
  defp parse_string_contents(<< ?\\, ?r,  json :: binary >>, acc), do: parse_string_contents(json, [ ?\r | acc ])
  defp parse_string_contents(<< ?\\, ?t,  json :: binary >>, acc), do: parse_string_contents(json, [ ?\t | acc ])
  defp parse_string_contents(<< ?\\, ?",  json :: binary >>, acc), do: parse_string_contents(json, [ ?"  | acc ])
  defp parse_string_contents(<< ?\\, ?\\, json :: binary >>, acc), do: parse_string_contents(json, [ ?\\ | acc ])
  defp parse_string_contents(<< ?\\, ?/,  json :: binary >>, acc), do: parse_string_contents(json, [ ?/  | acc ])

  defp parse_string_contents(<< ?\\, ?u , json :: binary >> , acc) do
    case parse_escaped_unicode_codepoint(json, 0, 0) do
      { :error, error_info } -> { :error, error_info }
      { :ok, decoded_unicode_codepoint, after_codepoint} ->
        case decoded_unicode_codepoint do
          << _ ::utf8 >> ->
            parse_string_contents(after_codepoint, [ decoded_unicode_codepoint | acc ])
          _ ->
            { :error, { :unexpected_token, << ?\\, ?u , json :: binary >> } }
        end
    end
  end

  defp parse_string_contents(<< char :: utf8, json :: binary >>, acc) do
    parse_string_contents(json, [ char | acc ])
  end


  # parse_escaped_unicode_codepoint tries to parse a valid hexadecimal (composed of 4 characters) value that potentially
  # represents a unicode codepoint
  defp parse_escaped_unicode_codepoint(json, acc, chars_parsed) when 4 === chars_parsed do
    try do
      { :ok, << acc :: utf8 >>, json }
    rescue _ in ArgumentError ->
      { :error, { :unexpected_token, json } }
    end
  end

  defp parse_escaped_unicode_codepoint(<< hex :: utf8, json :: binary >>, acc, chars_parsed) when hex in ?0..?9 do
    parse_escaped_unicode_codepoint(json, 16 * acc + hex - ?0, chars_parsed + 1)
  end

  defp parse_escaped_unicode_codepoint(<< hex :: utf8, json :: binary >>, acc, chars_parsed) when hex in ?a..?f do
    parse_escaped_unicode_codepoint(json, 16 * acc + 10 + hex - ?a, chars_parsed + 1)
  end

  defp parse_escaped_unicode_codepoint(<< hex :: utf8, json :: binary >>, acc, chars_parsed) when hex in ?A..?F do
    parse_escaped_unicode_codepoint(json, 16 * acc + 10 + hex - ?A, chars_parsed + 1)
  end

  defp parse_escaped_unicode_codepoint(<< >>, _, _), do: {:error, :unexpected_end_of_buffer}
  defp parse_escaped_unicode_codepoint(json, _, _), do: { :error, { :unexpected_token, json } }
end
