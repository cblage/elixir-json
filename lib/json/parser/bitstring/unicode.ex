defmodule JSON.Parser.Bitstring.Unicode do
  @doc """
  parses a valid chain of escaped unicode and returns the string representation,
  plus the remainder of the string

  ## Examples

      iex> JSON.Parser.Bitstring.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.parse "-hello"
      {:error, {:unexpected_token, "-hello"} }

  """
  def parse(<< ?\\, ?u , json :: binary >>), do: parse_escaped_unicode_codepoint(json, 0, 0)
  def parse(<< >>), do:  {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, { :unexpected_token, json }}



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
