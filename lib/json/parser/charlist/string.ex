defmodule JSON.Parser.Charlist.String do
  @doc """
  parses a valid JSON string, returns its elixir representation

  ## Examples

      iex> JSON.Parser.Charlist.String.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Charlist.String.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parser.Charlist.String.parse '-hello'
      {:error, {:unexpected_token, '-hello'} }

      iex> JSON.Parser.Charlist.String.parse '129245'
      {:error, {:unexpected_token, '129245'} }

      iex> JSON.Parser.Charlist.String.parse '\\\"7.something\\\"'
      {:ok, "7.something", '' }

      iex> JSON.Parser.Charlist.String.parse '\\\"star -> \\\\u272d <- star\\\"'
      {:ok, "star -> ✭ <- star", '' }

      iex> JSON.Parser.Charlist.String.parse '\\\"\\\\u00df ist wunderbar\\\"'
      {:ok, "ß ist wunderbar", '' }

      iex> JSON.Parser.Charlist.String.parse '\\\"-88.22suffix\\\" foo bar'
      {:ok, "-88.22suffix", ' foo bar' }

  """
  def parse([ ?" | rest ]), do: parse_string_contents(rest, [])
  def parse([ ]),  do: { :error, :unexpected_end_of_buffer }
  def parse(json), do: { :error, { :unexpected_token, json } }


  #stop conditions
  defp parse_string_contents([ ], _), do: { :error, :unexpected_end_of_buffer }
  defp parse_string_contents([ ?" | rest ], acc), do: { :ok, IO.iodata_to_binary(acc), rest }

  #parsing
  defp parse_string_contents([ ?\\, ?f  | rest ], acc), do: parse_string_contents(rest, [ acc, ?\f ])
  defp parse_string_contents([ ?\\, ?n  | rest ], acc), do: parse_string_contents(rest, [ acc, ?\n ])
  defp parse_string_contents([ ?\\, ?r  | rest ], acc), do: parse_string_contents(rest, [ acc, ?\r ])
  defp parse_string_contents([ ?\\, ?t  | rest ], acc), do: parse_string_contents(rest, [ acc, ?\t ])
  defp parse_string_contents([ ?\\, ?"  | rest ], acc), do: parse_string_contents(rest, [ acc, ?"  ])
  defp parse_string_contents([ ?\\, ?\\ | rest ], acc), do: parse_string_contents(rest, [ acc, ?\\ ])
  defp parse_string_contents([ ?\\, ?/  | rest ], acc), do: parse_string_contents(rest, [ acc, ?/  ])

  defp parse_string_contents([ ?\\, ?u  | rest ], acc) do
    case parse_unicode_escape(rest, 0, 0) do
      { :error, error_info } -> { :error, error_info }
      { :ok, decoded_codepoint, after_decoded_codepoint} ->
        case decoded_codepoint do
          << _ ::utf8 >> ->
            parse_string_contents(after_decoded_codepoint, [ acc, decoded_codepoint])
          _ ->
            { :error, { :unexpected_token, [?\\, ?u | rest] } } # copying only in case of error
        end
    end
  end

  # omnomnom, eat the next character
  defp parse_string_contents([ char | rest ], acc) do
    parse_string_contents(rest, [ acc, char ])
  end

  # The only OK stop condition (parsed 4 expected chars successfully)
  defp parse_unicode_escape(json, acc, chars_parsed) when 4 === chars_parsed do
    { :ok, << acc :: utf8 >>, json }
  end

  defp parse_unicode_escape([ ], _, _), do: { :error, :unexpected_end_of_buffer }

  defp parse_unicode_escape([char | rest], acc, chars_parsed) when char in ?0..?9 do
    parse_unicode_escape(rest, 16 * acc + char - ?0, chars_parsed + 1)
  end

  defp parse_unicode_escape([char | rest], acc, chars_parsed) when char in ?a..?f do
    parse_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_parsed + 1)
  end

  defp parse_unicode_escape([char | rest], acc, chars_parsed) when char in ?A..?F do
    parse_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_parsed + 1)
  end

  defp parse_unicode_escape(json, _, _), do: { :error, { :unexpected_token, json } }
end
