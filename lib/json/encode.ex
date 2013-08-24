defprotocol JSON.Encode do  
  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """

  
  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.Encode.to_json([result: "this will be a elixir result"]) 
      {:ok, "{\\\"result\\\":\\\"this will be a elixir result\\\"}"}
      
  """
  @spec to_json(term) :: bitstring
  def to_json(term)

  @doc """
  Returns an atom that reprsents the JSON type for the term

  ## Examples

      iex> JSON.Encode.typeof([result: "this will be a elixir result"]) 
      :object
      
  """
  @spec typeof(term) :: atom
  def typeof(term)
end

defimpl JSON.Encode, for: Tuple do
  def to_json(term), do: tuple_to_list(term) |> JSON.Encode.to_json
  def typeof(_), do: :array
end

defimpl JSON.Encode, for: List do
  def to_json([]), do: {:ok, "[]"}
  
  def to_json(list) do 
    if Keyword.keyword? list do 
      {:ok, "{" <> Enum.map_join(list, ",", fn {key, object} -> encode_item(key) <> ":" <>  encode_item(object) end) <> "}"}
    else
      {:ok, "[" <> Enum.map_join(list, ",", encode_item(&1)) <> "]"}
    end
  end

  defp encode_item (item) do 
    encode_result = JSON.Encode.to_json(item)
    case encode_result do 
      {:ok, encoded_item} -> encoded_item
      _ -> encode_result #propagate error, will trigger error in map_join
    end
  end

  def typeof([]), do: :array
   
  def typeof(list) do
    if (Keyword.keyword? list) do
      :object
    else
      :array
    end
  end
end

defimpl JSON.Encode, for: Number do
  def to_json(number), do: {:ok, "#{number}"} # Elixir convers octal, etc into decimal when putting in strings
  def typeof(_), do: :number
end

defimpl JSON.Encode, for: Atom do
  def to_json(nil), do: {:ok, "null"}
  def to_json(false), do: {:ok, "false"}
  def to_json(true),  do: {:ok, "true"}
  def to_json(atom) when is_atom(atom), do: atom_to_binary(atom) |> JSON.Encode.to_json

  def typeof(boolean) when is_boolean(boolean), do: :boolean   
  def typeof(nil), do: :null
  def typeof(atom) when is_atom(atom), do: :string
end

defimpl JSON.Encode, for: BitString do
  #32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  def to_json(bitstring), do: {:ok, <<?">> <> encode_binary_recursive(bitstring, "") <> <<?">>}

  defp encode_binary_recursive(<< head :: utf8, tail :: binary >>, accumulator) do
    encode_binary_recursive(tail, accumulator <> encode_binary_character(head))
  end

  defp encode_binary_recursive(<<>>, accumulator), do: accumulator
  

  defp encode_binary_character(?"),   do: <<?\\, ?">> 
  defp encode_binary_character(?\b),  do: <<?\\, ?b>>
  defp encode_binary_character(?\f),  do: <<?\\, ?f>> 
  defp encode_binary_character(?\n),  do: <<?\\, ?n>>
  defp encode_binary_character(?\r),  do: <<?\\, ?r>>
  defp encode_binary_character(?\t),  do: <<?\\, ?t>>
  defp encode_binary_character(?/),   do: <<?\\, ?/>>
  defp encode_binary_character('\\'), do: <<?\\, ?\\>>
  defp encode_binary_character(char) when is_number(char) and char < @acii_space, do: <<?\\, ?u>> <> encode_hexadecimal_unicode_control_character(char)

  #anything else besides these control characters, just let it through
  defp encode_binary_character(char) when is_number(char), do: <<char>>


  defp encode_hexadecimal_unicode_control_character(char) when is_number(char) do 
    integer_to_binary(char, 16) |> zero_pad(4)
  end

  defp zero_pad(string, desired_length) when is_bitstring(string) and is_number(desired_length) and desired_length > 0 do
    needed_padding_characters = String.length(string) - desired_length
    if needed_padding_characters > 0 do
      String.duplicate("0", needed_padding_characters) <>  string
    else
      string
    end
  end

  def typeof(_), do: :string
end

defimpl JSON.Encode, for: Record do
  def to_json(record), do: record.to_keywords |> JSON.Encode.to_json
  def typeof(_), do: :object
end

#TODO: maybe this should return the result of "inspect" ?
defimpl JSON.Encode, for: Any do
  @any_to_json "[Elixir.Any]"

  def to_json(_), do: JSON.Encode.to_json(@any_to_json)
  def typeof(_), do: JSON.Encode.typeof(@any_to_json)
end
