defmodule JSON.Parse.Bitstring.String do
  @doc """
  Consumes a valid JSON string, returns its elixir representation

  ## Examples

      iex> JSON.Parse.Bitstring.String.consume ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Bitstring.String.consume "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parse.Bitstring.String.consume "-hello"
      {:error, {:unexpected_token, "-hello"} }

      iex> JSON.Parse.Bitstring.String.consume "129245"
      {:error, {:unexpected_token, "129245"} }

      iex> JSON.Parse.Bitstring.String.consume "\\\"7.something\\\""
      {:ok, "7.something", "" }

      iex> JSON.Parse.Bitstring.String.consume "\\\"-88.22suffix\\\" foo bar"
      {:ok, "-88.22suffix", " foo bar" }

      iex> JSON.Parse.Bitstring.String.consume "\\\"star -> \\\\u272d <- star\\\""
      {:ok, "star -> ✭ <- star", "" }

      iex> JSON.Parse.Bitstring.String.consume "\\\"\\\\u00df ist wunderbar\\\""
      {:ok, "ß ist wunderbar", "" }

      iex> JSON.Parse.Bitstring.String.consume "\\\"Rafaëlla\\\" foo bar"
      {:ok, "Rafaëlla", " foo bar" }

      iex> JSON.Parse.Bitstring.String.consume "\\\"Éloise woot\\\" Éloise"
      {:ok, "Éloise woot", " Éloise" }
  """
  def consume(<< ?" :: utf8 , rest :: binary >>), do: consume_string_contents(rest, [ ])
  def consume(<< >>), do: { :error, :unexpected_end_of_buffer }
  def consume(json), do: { :error, { :unexpected_token, json } }


  #stop conditions
  defp consume_string_contents(<< >>, _), do: { :error, :unexpected_end_of_buffer }
  defp consume_string_contents(<< ?" :: utf8, rest :: binary >>, acc) do
    case List.to_string(acc) do
      {:ok, encoded_string } -> { :ok, encoded_string, rest }
      _ -> {:error, { :unexpected_token, rest }}
    end
  end

  #parsing
  defp consume_string_contents(<< ?\\, ?f,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\f ])
  defp consume_string_contents(<< ?\\, ?n,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\n ])
  defp consume_string_contents(<< ?\\, ?r,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\r ])
  defp consume_string_contents(<< ?\\, ?t,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\t ])
  defp consume_string_contents(<< ?\\, ?",  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?"  ])
  defp consume_string_contents(<< ?\\, ?\\, rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\\ ])
  defp consume_string_contents(<< ?\\, ?/,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?/  ])

  defp consume_string_contents(<< ?\\, ?u , rest :: binary >> , acc) do
    case consume_unicode_escape(rest, 0, 0) do
     { :error, error_info } -> { :error, error_info }
     { :ok, decoded_codepoint, after_decoded_codepoint} ->
        case decoded_codepoint do
          << _ ::utf8 >> ->
            consume_string_contents(after_decoded_codepoint, [ acc, decoded_codepoint ])
          _ ->
            { :error, { :unexpected_token, << ?\\, ?u , rest :: binary >> } }
        end
    end
  end

  defp consume_string_contents(<< char :: utf8, rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, char ])


  # The only OK stop condition (consumed 4 expected chars successfully)
  defp consume_unicode_escape(json, acc, chars_consumed) when 4 === chars_consumed do
    { :ok, << acc :: utf8 >>, json }
  end

  defp consume_unicode_escape(<< >>, _, _), do: {:error, :unexpected_end_of_buffer}

  defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?0..?9 do
    consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1)
  end

  defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?a..?f do
    consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1)
  end

  defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?A..?F do
    consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1)
  end

  defp consume_unicode_escape(json, _, _), do: { :error, { :unexpected_token, json } }
end
