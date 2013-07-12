defprotocol JsonEncoder do
  
  @moduledoc """
  Defines the protocol required for encoding basic elixir types into valid JSON content
  """

  @only [Atom, BitString, Number]

  def encode_string(item)
  
  def encode_number(item)
 
end

defimpl JsonEncoder, for: BitString do

  def encode_string(bitstring) do
    "\"" <> _encode_binary_recursive(bitstring, "") <> "\""
  end

  def encode_number(_) do 
    ##need regexp here for digits and print the string if its only digits or NaN otherwise
    "NaN"
  end

  defp _encode_binary_recursive(<< head :: utf8, tail :: binary >>, accumulator) do
    _encode_binary_recursive(tail, accumulator <> _encode_binary_character(head))
  end

  defp _encode_binary_recursive(<<>>, accumulator) do
    accumulator
  end

  defp  _encode_binary_character(?"),   do: "\\\""
  defp  _encode_binary_character(?\b),  do: "\\b"
  defp  _encode_binary_character(?\f),  do: "\\f"
  defp  _encode_binary_character(?\n),  do: "\\n"
  defp  _encode_binary_character(?\r),  do: "\\r"
  defp  _encode_binary_character(?\t),  do: "\\t"
  defp  _encode_binary_character(?/),   do: "\\/"
  defp  _encode_binary_character('\\'), do: "\\\\"
  
  #Anything else < ' ', ascii space = 32
  defp  _encode_binary_character(char) when is_number(char) and char < 32, do: "\u#{_encode_hexadecimal_unicode_control_character(char)}"

  #anything else besides these control characters
  defp  _encode_binary_character(char) when is_number(char), do: <<char>>


  defp _encode_hexadecimal_unicode_control_character(char) when is_number(char) do 
    integer_to_binary(char, 16)
      |> _zero_pad_string(4)
  end

  defp _zero_pad_string(string, desired_length) when is_bitstring(string) and is_number(desired_length) and desired_length > 0 do
    string_length = String.length(string)
    if (string_length >= desired_length) do 
      string
    else 
      _zero_pad_string_recursive(string, string_length - desired_length)
    end
  end

  defp _zero_pad_string_recursive(string, iterations_left) when is_bitstring(string and is_number(iterations_left) and iterations_left > 0 ) do
    _zero_pad_string_recursive("0" <> string, iterations_left - 1)
  end

  defp _zero_pad_string_recursive(string, 0) when is_bitstring(string) do
    string
  end

end


defimpl JsonEncoder, for: Number do

  def encode_string(number) do
    encode_number(number) #truns it into a string
      |>JsonEncoder.encode_string #adds the quotes, etc
  end

  def encode_number(number), do: "#{number}" # Elixir convers octal, etc into decimal when putting in strings

end


defimpl JsonEncoder, for: Atom do
  
  def encode_string(nil),   do: "\"\""
  def encode_string(false), do: "\"false\""
  def encode_string(true),  do: "\"true\""

  def encode_string(atom) when is_atom(atom) do 
    atom_to_binary(atom, :utf8)
      |>JsonEncoder.encode_string
  end

  def encode_number(nil),   do: "0"
  def encode_number(false), do: "0"
  def encode_number(true),  do: "1"
  def encode_number(_),     do: "NaN"

end