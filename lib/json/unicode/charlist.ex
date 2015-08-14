defmodule JSON.Unicode.Charlist do
  @doc """
  parses a valid chain of escaped unicode and returns the string representation,
  plus the remainder of the string

  ## Examples

      iex> JSON.Unicode.Charlist.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Unicode.Charlist.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Unicode.Charlist.parse '-hello'
      {:error, {:unexpected_token, '-hello'} }
  """
  def parse([ ?\\, ?u  | json ]), do: parse_hex(json, [ ])
  def parse([ ]),  do:  { :error, :unexpected_end_of_buffer }
  def parse(json), do:  { :error, { :unexpected_token, json } }


  defp parse_hex([ ], _), do: {:error, :unexpected_end_of_buffer}

  defp parse_hex(json, hex_acc) do
    case parse_hex_code(json, 0, 0) do
        foo -> foo
        # TODO: make this use moar hex_acc
    end
  end


  # this converts the bytes acc to utf8
  defp acc_to_utf8(acc, json) do
    try do
      { :ok, << acc :: utf8 >>, json }
    rescue _ in ArgumentError ->
      { :error, { :invalid_utf8, json } }
    end
  end

  # parse_hex tries to parse a valid hexadecimal (composed of 4 characters)
  defp parse_hex_code(json, hex, chars_parsed) when 4 === chars_parsed do
    acc_to_utf8(hex, json)
    # TODO: start here, dude
  end

  defp parse_hex_code([ ], _, _), do: { :error, :unexpected_end_of_buffer }

  defp parse_hex_code([ hex | json], acc, chars_parsed) when hex in ?0..?9 do
    parse_hex_code(json, 16 * acc + hex - ?0, chars_parsed + 1)
  end

  defp parse_hex_code([ hex | json], acc, chars_parsed) when hex in ?a..?f do
    parse_hex_code(json, 16 * acc + 10 + hex - ?a, chars_parsed + 1)
  end

  defp parse_hex_code([ hex | json], acc, chars_parsed) when hex in ?A..?F do
    parse_hex_code(json, 16 * acc + 10 + hex - ?A, chars_parsed + 1)
  end

  defp parse_hex_code(json, _, _), do: { :error, { :unexpected_token, json } }

end
