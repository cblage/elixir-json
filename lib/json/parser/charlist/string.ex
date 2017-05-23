defmodule JSON.Parser.Charlist.String do

  use Bitwise
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
  def parse([ ?" | tail ]), do: parse_string_contents(tail, [])
  def parse([ ]),  do: { :error, :unexpected_end_of_buffer }
  def parse(json), do: { :error, { :unexpected_token, json } }


  #stop conditions
  defp parse_string_contents([ ], _), do: { :error, :unexpected_end_of_buffer }

  # found the closing ", lets reverse the acc and encode it as a string!
  defp parse_string_contents([ ?" | json ], acc) do
    case Enum.reverse(acc) |> List.to_string do
      encoded when is_binary(encoded) ->
        { :ok, encoded, json }
      _ ->
        {:error, { :unexpected_token, json }}
    end
  end

  #parsing
  defp parse_string_contents([ ?\\, ?f  | json ], acc), do: parse_string_contents(json, [ ?\f | acc ])
  defp parse_string_contents([ ?\\, ?n  | json ], acc), do: parse_string_contents(json, [ ?\n | acc ])
  defp parse_string_contents([ ?\\, ?r  | json ], acc), do: parse_string_contents(json, [ ?\r | acc ])
  defp parse_string_contents([ ?\\, ?t  | json ], acc), do: parse_string_contents(json, [ ?\t | acc ])
  defp parse_string_contents([ ?\\, ?"  | json ], acc), do: parse_string_contents(json, [ ?"  | acc ])
  defp parse_string_contents([ ?\\, ?\\ | json ], acc), do: parse_string_contents(json, [ ?\\ | acc ])
  defp parse_string_contents([ ?\\, ?/  | json ], acc), do: parse_string_contents(json, [ ?/  | acc ])

  defp parse_string_contents(char = [ ?\\, ?u  | _ ], acc) do
    case JSON.Parser.Charlist.Unicode.parse(char) do
      { :error, error_info } ->
        { :error, error_info }
      { :ok, decoded_unicode_codepoint, after_codepoint} ->
        case decoded_unicode_codepoint do
          << _ ::utf8 >> ->
            parse_string_contents(after_codepoint, [ decoded_unicode_codepoint | acc ])
          _ ->
            { :error, { :unexpected_token, char} }
        end
    end
  end


  # omnomnom, eat the next character
  defp parse_string_contents([ char | json ], acc) do
    parse_string_contents(json, [ char | acc ])
  end
end
