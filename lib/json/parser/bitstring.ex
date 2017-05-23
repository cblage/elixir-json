defmodule JSON.Parser.Bitstring do
  use Bitwise

  @doc """
  parses a valid JSON value, returns its elixir representation

  ## Examples

      iex> JSON.Parser.Bitstring.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.parse "-hello"
      {:error, {:unexpected_token, "-hello"} }

      iex> JSON.Parser.Bitstring.parse "129245"
      {:ok, 129245, "" }

      iex> JSON.Parser.Bitstring.parse "7.something"
      {:ok, 7, ".something" }

      iex> JSON.Parser.Bitstring.parse "-88.22suffix"
      {:ok, -88.22, "suffix" }

      iex> JSON.Parser.Bitstring.parse "-12e4and then some"
      {:ok, -1.2e+5, "and then some" }

      iex> JSON.Parser.Bitstring.parse "7842490016E-12-and more"
      {:ok, 7.842490016e-3, "-and more" }

      iex> JSON.Parser.Bitstring.parse "null"
      {:ok, nil, ""}

      iex> JSON.Parser.Bitstring.parse "false"
      {:ok, false, "" }

      iex> JSON.Parser.Bitstring.parse "true"
      {:ok, true, "" }

      iex> JSON.Parser.Bitstring.parse "\\\"7.something\\\""
      {:ok, "7.something", "" }

      iex> JSON.Parser.Bitstring.parse "\\\"-88.22suffix\\\" foo bar"
      {:ok, "-88.22suffix", " foo bar" }

      iex> JSON.Parser.Bitstring.parse "\\\"star -> \\\\u272d <- star\\\""
      {:ok, "star -> ✭ <- star", "" }

      iex> JSON.Parser.Bitstring.parse "[]"
      {:ok, [], "" }

      iex> JSON.Parser.Bitstring.parse "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:ok, ["foo", 1, 2, 1.5], " lala" }

      iex> JSON.Parser.Bitstring.parse "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), " lalal"}
  """

  def parse(<< >>), do:  {:error, :unexpected_end_of_buffer}
  def parse(<< ?[, json :: binary >>), do: json |> trim |> parse_array_contents([])
  def parse(<< ?{, json :: binary >>), do: json|> trim |> parse_object_contents(Map.new)
  def parse(<< ?", json :: binary >>), do: parse_string_recursive(json, [])

  def parse(<< ?n, ?u, ?l, ?l, rest :: binary >>), do: { :ok, nil,   rest }
  def parse(<< ?t, ?r, ?u, ?e, rest :: binary >>), do: { :ok, true,  rest }
  def parse(<< ?f, ?a, ?l, ?s, ?e, rest :: binary >>), do: { :ok, false, rest }

  def parse(<< ?- , number :: utf8, rest :: binary >>) when number in ?0..?9 do
    case parse(<< number :: utf8, rest:: binary >>) do
      { :ok, number, json } -> { :ok, -1 * number, json }
      { :error, error_info } -> { :error, error_info }
    end
  end

  def parse(<< number :: utf8, _ :: binary >> = bin) when number in ?0..?9 do
    bin |> to_integer |> add_fractional |> apply_exponent
  end

  def parse(<< >>), do: { :error, :unexpected_end_of_buffer }
  def parse(<< json :: binary >>), do: {:error, { :unexpected_token, json }}

  defp parse_array_contents(<< >>, _), do: { :error,  :unexpected_end_of_buffer }
  defp parse_array_contents(<< ?], rest :: binary >>, acc), do: terminate_array_contents(rest, acc)
  defp parse_array_contents(<< json :: binary >>, acc) do
    case json |> trim |> parse do
      { :error, error_info } -> { :error, error_info }
      {:ok, value, after_value } ->
        case trim(after_value) do
          << ?, , after_comma :: binary >> -> parse_array_contents(trim(after_comma), [value | acc])
          something -> parse_array_contents(something, [value | acc])
        end
    end
  end

  defp terminate_array_contents(<< rest :: binary >>, acc) do
    { :ok, Enum.reverse(acc), rest }
  end

  # Object Parsing
  defp parse_object_key(<< json:: binary >>) do
    case parse_string_recursive(json, []) do
      {:error, error_info} -> {:error, error_info}
      {:ok, key, after_key } ->
        case trim(after_key) do
          << >> -> { :error, :unexpected_end_of_buffer}
          << ?:,  after_colon :: binary >> -> { :ok, key, trim(after_colon) }
          something -> { :error, { :unexpected_token, trim(something) } }
        end
    end
  end

  defp parse_object_value(key, after_key, acc) do
    case parse(after_key) do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, after_value } ->
        new_acc = Map.put(acc, key, value)
        case trim(after_value) do
          << ?,, after_comma :: binary >> -> parse_object_contents(trim(after_comma), new_acc)
          something -> parse_object_contents(something, new_acc)
        end
    end
  end

  defp parse_object_contents(<< ?}, rest :: binary >>, acc), do: terminate_object_contents(rest, acc)
  defp parse_object_contents(<< >>, _), do: { :error, :unexpected_end_of_buffer }
  defp parse_object_contents(<< ?", rest :: binary >>, acc) do
    case parse_object_key(rest) do
      { :error, error_info }  -> { :error, error_info }
      { :ok, key, after_key } -> parse_object_value(key, after_key, acc)
    end
  end
  defp parse_object_contents(json, _), do: { :error, { :unexpected_token, json } }

  defp terminate_object_contents(<< rest :: binary >>, acc) do
    { :ok, acc, rest }
  end

  #String parsing

  #stop conditions
  defp parse_string_recursive(<< >>, _), do: { :error, :unexpected_end_of_buffer }

  # found the closing ", lets reverse the acc and encode it as a string!
  defp parse_string_recursive(<< ?" :: utf8, json :: binary >>, acc) do
    terminate_string_parsing(json, acc)
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
    case parse_escaped_unicode_codepoint(json, 0, 0) do
      { :error, error_info } -> { :error, error_info }
      { :ok, decoded_unicode_codepoint, after_codepoint} -> parse_string_recursive(after_codepoint, [ decoded_unicode_codepoint | acc ])
    end
  end

  defp parse_string_recursive(<< char :: utf8, json :: binary >>, acc) do
    parse_string_recursive(json, [ char | acc ])
  end

  defp terminate_string_parsing(<< json :: binary >>, acc) do
    { :ok, acc |> Enum.reverse |> List.to_string, json }
  end

  # parse_escaped_unicode_codepoint tries to parse a valid hexadecimal (composed of 4 characters) value that potentially
  # represents a unicode codepoint
  defp parse_escaped_unicode_codepoint(json, acc, 4), do: { :ok, << acc :: utf8 >>, json }

  # Parsing sugorrogate pairs
  # http://unicodebook.readthedocs.org/unicode_encodings.html#utf-16-surrogate-pairs
  # Inspired by Poison's function
  defp parse_escaped_unicode_codepoint(<< ?d, hex :: utf8, f1, f2 , ?\\, ?u, ?d, hex2:: utf8, s1, s2, json :: binary >>, _, 0)
  when (hex >= 56) do
    first_part = (List.to_integer( [?d, hex, f1, f2], 16) &&& 1023) <<< 10
    second_part = List.to_integer( [?d, hex2, s1, s2], 16) &&& 1023
    complete = 0x10000 + first_part + second_part
    {:ok, <<  complete :: utf8 >>, json}
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
  defp parse_escaped_unicode_codepoint(<< json :: binary >>, _, _), do: { :error, { :unexpected_token, json } }


  # Numbers
  defp add_fractional({ :error, error_info }), do: { :error, error_info }
  defp add_fractional({ :ok, acc, << ?., c :: utf8, rest :: binary >>}) when c in ?0..?9 do
   { fractional, rest } = parse_fractional(<< c :: utf8, rest :: binary >>, 0, 10.0)
   { :ok, acc + fractional, rest }
  end
  defp add_fractional(result), do: result

  defp parse_fractional(<< number :: utf8, rest :: binary >>, acc, power) when number in ?0..?9 do
    parse_fractional(rest, acc + (number - ?0) / power, power * 10)
  end
  defp parse_fractional(json, acc , _) when is_binary(json), do: { acc, json }


  defp apply_exponent({ :error, error_info }), do: { :error, error_info }
  defp apply_exponent({ :ok, acc, << exponent :: utf8, rest :: binary >> }) when exponent in 'eE' do
    case to_integer(rest) do
      { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
      { :error, error_info } -> { :error, error_info }
    end
  end
  defp apply_exponent({ :ok, acc, json }), do: { :ok, acc, json }

  defp to_integer(<< >>), do: { :error,  :unexpected_end_of_buffer }
  defp to_integer(<< json :: binary >>) do
    case Integer.parse(json) do
      { :error, _ } -> { :error, { :unexpected_token, json } }
      { result, rest } -> {:ok, result, rest}
    end
  end

  @doc """
  parses valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parser.Bitstring.trim ""
      ""

      iex> JSON.Parser.Bitstring.trim "xkcd"
      "xkcd"

      iex> JSON.Parser.Bitstring.trim "  \\t\\r lalala "
      "lalala "

      iex> JSON.Parser.Bitstring.trim " \\n\\t\\n fooo \\u00dflalalal "
      "fooo \\u00dflalalal "
  """
  #32 = ascii space, clearer than using "? ", I think
  def trim(<< 32  :: utf8, rest :: binary >>), do: trim(rest)
  def trim(<< ?\t :: utf8, rest :: binary >>), do: trim(rest)
  def trim(<< ?\r :: utf8, rest :: binary >>), do: trim(rest)
  def trim(<< ?\n :: utf8, rest :: binary >>), do: trim(rest)
  def trim(bitstring), do: bitstring
end
