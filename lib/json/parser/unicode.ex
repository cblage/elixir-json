defmodule JSON.Parser.Unicode do
  @moduledoc """
  Implements a JSON Unicode Parser for Bitstring values
  """

  use Bitwise

  @doc """
  parses a valid chain of escaped unicode and returns the string representation,
  plus the remainder of the string

  ## Examples

      iex> JSON.Parser.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Parser.parse "-hello"
      {:error, {:unexpected_token, "-hello"}}

  """
  def parse(<<?\\, ?u, json::binary>>), do: parse_escaped_unicode_codepoint(json, 0, 0)
  def parse(<<>>), do: {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, {:unexpected_token, json}}

  # Parsing sugorrogate pairs
  # http://unicodebook.readthedocs.org/unicode_encodings.html
  # Inspired by Poison's function
  defp parse_escaped_unicode_codepoint(
         <<?d, hex::utf8, f1, f2, ?\\, ?u, ?d, hex2::utf8, s1, s2, json::binary>>,
         _,
         0
       )
       when hex >= 56 do
    first_part = (List.to_integer([?d, hex, f1, f2], 16) &&& 1023) <<< 10
    second_part = List.to_integer([?d, hex2, s1, s2], 16) &&& 1023
    complete = 0x10000 + first_part + second_part
    {:ok, <<complete::utf8>>, json}
  end

  # parse_escaped_unicode_codepoint tries to parse
  # a valid hexadecimal (composed of 4 characters) value that potentially
  # represents a unicode codepoint
  defp parse_escaped_unicode_codepoint(json, acc, chars_parsed) when 4 === chars_parsed do
    {:ok, <<acc::utf8>>, json}
  end

  defp parse_escaped_unicode_codepoint(<<hex::utf8, json::binary>>, acc, chars_parsed)
       when hex in ?0..?9 do
    parse_escaped_unicode_codepoint(json, 16 * acc + hex - ?0, chars_parsed + 1)
  end

  defp parse_escaped_unicode_codepoint(<<hex::utf8, json::binary>>, acc, chars_parsed)
       when hex in ?a..?f do
    parse_escaped_unicode_codepoint(json, 16 * acc + 10 + hex - ?a, chars_parsed + 1)
  end

  defp parse_escaped_unicode_codepoint(<<hex::utf8, json::binary>>, acc, chars_parsed)
       when hex in ?A..?F do
    parse_escaped_unicode_codepoint(json, 16 * acc + 10 + hex - ?A, chars_parsed + 1)
  end

  defp parse_escaped_unicode_codepoint(<<>>, _, _), do: {:error, :unexpected_end_of_buffer}
  defp parse_escaped_unicode_codepoint(json, _, _), do: {:error, {:unexpected_token, json}}
end
