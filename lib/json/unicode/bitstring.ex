defmodule JSON.Unicode.Bitstring do
  @doc """
  parses a valid chain of escaped unicode and returns the string representation,
  plus the remainder of the string

String.fromCodePoint(42);       // "*"
String.fromCodePoint(65, 90);   // "AZ"
String.fromCodePoint(0x404);    // "\u0404"
String.fromCodePoint(0x2F804);  // "\uD87E\uDC04"
String.fromCodePoint(194564);   // "\uD87E\uDC04"
String.fromCodePoint(0x1D306, 0x61, 0x1D307) // "\uD834\uDF06a\uD834\uDF07"

String.fromCodePoint('_');      // RangeError
String.fromCodePoint(Infinity); // RangeError
String.fromCodePoint(-1);       // RangeError
String.fromCodePoint(3.14);     // RangeError
String.fromCodePoint(3e-2);     // RangeError
String.fromCodePoint(NaN);      // RangeError

  ## Examples

      iex> JSON.Parser.Bitstring.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.parse "-hello"
      {:error, {:unexpected_token, "-hello"} }

  """
  def parse(<< ?\\, ?u , json :: binary >>), do:  parse_hex(json, << >>)
  def parse(<< >>), do:  {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, { :unexpected_token, json }}



  defp parse_hex(<< >>, _), do: {:error, :unexpected_end_of_buffer}

  defp parse_hex(json, hex_acc) do
    case parse_hex_code(json, 0, 0) do
      foo -> foo
      # TODO: make this use moar hex_acc
    end
  end

  #defp parse_hex(json, _), do: { :error, { :unexpected_token, json } }


  # https://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
  # Converting between code points and surrogate pairs

  # Section 3.7 of The Unicode Standard 3.0 defines the algorithms for converting to and from surrogate pairs.
  #
  # A code point C greater than 0xFFFF corresponds to a surrogate pair <H, L> as per the following formula:
  #
  # H = Math.floor((C - 0x10000) / 0x400) + 0xD800
  # L = (C - 0x10000) % 0x400 + 0xDC00
  # The reverse mapping, i.e. from a surrogate pair <H, L> to a Unicode code point C, is given by:
  #
  # C = (H - 0xD800) * 0x400 + L - 0xDC00 + 0x10000
  # Ok, so what about JavaScript?
  # ECMAScript, the standardized version of JavaScript, defines how characters should be interpreted:
  #

  #defp codePointAt(index) do
  #  // Get the first code unit
  #  val highSurrogate = string.charCodeAt(index)
  #  if ( // check if it’s the start of a surrogate pair
  #    highSurrogate >= 0xD800 && highSurrogate <= 0xDBFF &&
  #    string.length > index + 1 # there is a next code unit
  #  ) {
  #    lowSurrogate = string.charCodeAt(index + 1);
  #    if (lowSurrogate >= 0xDC00 && lowSurrogate <= 0xDFFF) { // low surrogate
  #      // https://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
  #      return (highSurrogate - 0xD800) * 0x400 + lowSurrogate - 0xDC00 + 0x10000;
  #    }
  #  } else {
  #    string.charCodeAt(index)
  #  }
  #end

  defp acc_to_utf8(acc, json) do
    try do
      { :ok, << acc :: utf8 >>, json }
    rescue _ in ArgumentError ->
      { :error, { :invalid_utf8, json } }
    end
  end

  # parse_hex_code tries to parse a valid hexadecimal (composed of 4 characters)
  defp parse_hex_code(json, hex, chars_parsed) when 4 === chars_parsed do
    acc_to_utf8(hex, json)
    # TODO: start here, dude
  end

  defp parse_hex_code(<< >>, _, _), do: {:error, :unexpected_end_of_buffer}

  defp parse_hex_code(<< hex :: utf8, json :: binary >>, acc, chars_parsed) when hex in ?0..?9 do
    parse_hex_code(json, 16 * acc + hex - ?0, chars_parsed + 1)
  end

  defp parse_hex_code(<< hex :: utf8, json :: binary >>, acc, chars_parsed) when hex in ?a..?f do
    parse_hex_code(json, 16 * acc + 10 + hex - ?a, chars_parsed + 1)
  end

  defp parse_hex_code(<< hex :: utf8, json :: binary >>, acc, chars_parsed) when hex in ?A..?F do
    parse_hex_code(json, 16 * acc + 10 + hex - ?A, chars_parsed + 1)
  end

  defp parse_hex_code(json, _, _), do: { :error, { :unexpected_token, json } }
end
