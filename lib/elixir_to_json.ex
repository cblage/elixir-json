defprotocol ElixirToJson do
  
  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """

  @only [Atom, Record, BitString, Tuple, List, Number, Any]

  def encode(item)

  def typeof(item)

end

defimpl ElixirToJson, for: Tuple do
  def encode(item) do
      tuple_to_list(item)
        |>ElixirToJson.encode
  end

  def typeof(_) do
    ElixirToJson.typeof([]) # same as for arrays
  end
end

defimpl ElixirToJson, for: List do
  
  def encode([]) do 
    "[]"
  end

  def encode(list) do 
    if (Keyword.keyword? list) do
      "{#{_encode_keyword(list, "")}}"
    else 
      "[#{_encode_list(list, "")}]"
    end
  end
  

  defp _encode_keyword([], accumulator) when is_bitstring(accumulator) do 
    accumulator
  end

  defp _encode_keyword([head|tail], "") do 
    _encode_keyword(tail, _encode_keyword_item(head))
  end
  
  defp _encode_keyword([head|tail], accumulator) when is_bitstring(accumulator) do 
      _encode_keyword(tail, accumulator <> "," <> _encode_keyword_item(head))
  end

  defp _encode_keyword_item({key, object}) do 
    "\"#{key}\":" <>  ElixirToJson.encode(object)
  end

  defp _encode_list([], accumulator) when  is_bitstring(accumulator) do 
    accumulator
  end

  defp _encode_list([head|tail], "") do 
    _encode_list(tail, ElixirToJson.encode(head))
  end

  defp _encode_list([head|tail], accumulator) when is_bitstring(accumulator) do 
    _encode_list(tail, accumulator <> "," <> ElixirToJson.encode(head))
  end

  def typeof([]) do 
    :array
  end
 
  def typeof(list) do
    if (Keyword.keyword? list) do
      :object
    else
      :array
    end
  end
end

defimpl ElixirToJson, for: Number do
  def encode(item) do 
    "#{item}" # doesnt encode all cases properly
  end

  def typeof(_) do 
    :number
  end
end

defimpl ElixirToJson,  for: Record do
  def encode(record) do 
    inspect(record) # failing implementation
  end

  def typeof(_) do 
    :object
  end
end

defimpl ElixirToJson, for: [Atom, BitString] do
   def encode(false) do
    "false"
  end

  def encode(true) do
    "true"
  end
  
  def encode(nil) do
    "null"
  end

  def encode(atom_or_bitstring) when is_atom(atom_or_bitstring) or is_bitstring(atom_or_bitstring) do 
    "\"#{atom_or_bitstring}\"" # doesnt escape / encode anything
  end

  def typeof(boolean) when is_boolean(boolean) do
    :boolean
  end
  
  def typeof(nil) do 
    :null
  end

  def typeof(atom_or_bitstring) when is_atom(atom_or_bitstring) or is_bitstring(atom_or_bitstring) do
    :string
  end
end
  
defimpl ElixirToJson, for: [Any] do
  def encode(item) do 
    inspect(item) # very wrong implementation
  end

  def typeof(_) do
    :string
  end
end
