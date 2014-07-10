defmodule JSON.Encode.Error do
  @message "An error occurred while encoding the JSON object"
  defexception message: nil
  def exception(empty) when empty == nil or empty == '' do
    %JSON.Encode.Error{message: @message}
  end
  def exception(error_info) do
    %JSON.Encode.Error{message: @message <> " >>#{error_info}<<"}
  end
end

defprotocol JSON.Encode do
  @fallback_to_any true

  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """


  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.Encode.to_json([result: "this will be a elixir result"])
      {:ok, "{\\\"result\\\":\\\"this will be a elixir result\\\"}"}

  """
  @spec to_json(term) :: {:ok, bitstring} | {:error, term}
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
  def to_json(term), do: Tuple.to_list(term) |> JSON.Encode.Helpers.enum_to_json
  def typeof(_), do: :array
end

defimpl JSON.Encode, for: HashDict do
  def to_json(dict), do: JSON.Encode.Helpers.dict_to_json(dict)
  def typeof(_), do: :object
end

defimpl JSON.Encode, for: List do
  def to_json([]), do: {:ok, "[]"}

  def to_json(list) do
    if Keyword.keyword? list do
      JSON.Encode.Helpers.dict_to_json(list)
    else
      JSON.Encode.Helpers.enum_to_json(list)
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

defimpl JSON.Encode, for: [Integer, Float] do
  def to_json(number), do: {:ok, "#{number}"} # Elixir convers octal, etc into decimal when putting in strings
  def typeof(_), do: :number
end
File
defimpl JSON.Encode, for: Atom do
  def to_json(nil), do: {:ok, "null"}
  def to_json(false), do: {:ok, "false"}
  def to_json(true),  do: {:ok, "true"}
  def to_json(atom) when is_atom(atom), do: Atom.to_string(atom) |> JSON.Encode.to_json

  def typeof(boolean) when is_boolean(boolean), do: :boolean
  def typeof(nil), do: :null
  def typeof(atom) when is_atom(atom), do: :string
end

defimpl JSON.Encode, for: BitString do
  #32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  def to_json(bitstring), do: {:ok, <<?">> <> encode_binary_recursive(bitstring, []) <> <<?">>}

  defp encode_binary_recursive(<< head :: utf8, tail :: binary >>, acc) do
    encode_binary_recursive(tail, encode_binary_character(head, acc))
  end

  defp encode_binary_recursive(<<>>, acc), do: Enum.reverse(acc) |> to_string


  defp encode_binary_character(?",   acc),  do: [?", ?\\  | acc]
  defp encode_binary_character(?\b,  acc),  do: [?b, ?\\  | acc]
  defp encode_binary_character(?\f,  acc),  do: [?f, ?\\  | acc]
  defp encode_binary_character(?\n,  acc),  do: [?n, ?\\  | acc]
  defp encode_binary_character(?\r,  acc),  do: [?r, ?\\  | acc]
  defp encode_binary_character(?\t,  acc),  do: [?t, ?\\  | acc]
  defp encode_binary_character(?/,   acc),  do: [?/, ?\\  | acc]
  defp encode_binary_character(?\\,  acc),  do: [?\\, ?\\ | acc]
  defp encode_binary_character(char, acc) when is_number(char) and char < @acii_space do
    encode_hexadecimal_unicode_control_character(char, [?u,  ?\\ | acc])
  end

  #anything else besides these control characters, just let it through
  defp encode_binary_character(char, acc) when is_number(char), do: [ char | acc ]

  defp encode_hexadecimal_unicode_control_character(char, acc) when is_number(char) do
    [Integer.to_string(char, 16) |> zeropad_hexadecimal_unicode_control_character | acc]
  end

  defp zeropad_hexadecimal_unicode_control_character(<<a, b, c, d>>), do: [a,  b, c, d]
  defp zeropad_hexadecimal_unicode_control_character(<<a, b, c>>), do: [?0,  a,  b, c]
  defp zeropad_hexadecimal_unicode_control_character(<<a, b>>),    do: [?0, ?0,  a, b]
  defp zeropad_hexadecimal_unicode_control_character(<<a>>),       do: [?0, ?0, ?0, a]

  def typeof(_), do: :string
end

defimpl JSON.Encode, for: Record do
  def to_json(record), do: record.to_keywords |> JSON.Encode.Helpers.dict_to_json
  def typeof(_), do: :object
end

# Encodes maps into object
# > {:ok, "{\"a\":1,\"b\":2}"} = JSON.encode(%{a: 1, b: 2})
defimpl JSON.Encode, for: Map do
  def to_json(map), do: map |> JSON.Encode.Helpers.dict_to_json
  def typeof(_), do: :object
end

#TODO: maybe this should return the result of "inspect" ?
defimpl JSON.Encode, for: Any do
  @any_to_json "[Elixir.Any]"

  def to_json(_), do: JSON.Encode.to_json(@any_to_json)
  def typeof(_), do: JSON.Encode.typeof(@any_to_json)
end

defmodule JSON.Encode.Helpers do
  @moduledoc """
  Helper functions for writing JSON.Encode instances.
  """

  @doc """
  Given an enumerable encode the enumerable as an array.
  """
  def enum_to_json(coll) do
    {:ok, "[" <> Enum.map_join(coll, ",", &encode_item(&1)) <> "]"}
  end

  @doc """
  Given an enumerable that yields tuples of `{key, value}` encode the enumerable
  as an object.
  """
  def dict_to_json(coll) do
     {:ok, "{" <> Enum.map_join(coll, ",", fn {key, object} -> encode_item(key) <> ":" <>  encode_item(object) end) <> "}"}
  end

  defp encode_item(item) do
    encode_result = JSON.Encode.to_json(item)
    case encode_result do
      {:ok, encoded_item} -> encoded_item
      _ -> encode_result #propagate error, will trigger error in map_join
    end
  end
end
