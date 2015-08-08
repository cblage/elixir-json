defmodule JSON.Encoder.Error do
  defexception [error_info: nil]

  def message(exception) do
    error_message = "An error occurred while encoding the JSON object"
    if nil != exception.error_info  do
      error_message <> " >>#{exception.error_info}<<"
    else
      error_message
    end
  end
end

defprotocol JSON.Encoder do
  @fallback_to_any true

  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """


  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.Encoder.encode([result: "this will be a elixir result"])
      {:ok, "{\\\"result\\\":\\\"this will be a elixir result\\\"}"}

  """
  @spec encode(term) :: bitstring
  def encode(term)

  @doc """
  Returns an atom that reprsents the JSON type for the term

  ## Examples

      iex> JSON.Encoder.typeof([result: "this will be a elixir result"])
      :object

  """
  @spec typeof(term) :: atom
  def typeof(term)
end

defimpl JSON.Encoder, for: Tuple do
  def encode(term), do: Tuple.to_list(term) |> JSON.Encoder.Helpers.enum_encode
  def typeof(_), do: :array
end

defimpl JSON.Encoder, for: HashDict do
  def encode(dict), do: JSON.Encoder.Helpers.dict_encode(dict)
  def typeof(_), do: :object
end

defimpl JSON.Encoder, for: List do
  def encode([]), do: {:ok, "[]"}

  def encode(list) do
    if Keyword.keyword? list do
      JSON.Encoder.Helpers.dict_encode(list)
    else
      JSON.Encoder.Helpers.enum_encode(list)
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

# TODO: get rid of "Number" when we want to phase out 10.3 support.
defimpl JSON.Encoder, for: [Number, Integer, Float] do
  def encode(number), do: {:ok, "#{number}"} # Elixir convers octal, etc into decimal when putting in strings
  def typeof(_), do: :number
end

defimpl JSON.Encoder, for: Atom do
  def encode(nil), do: {:ok, "null"}
  def encode(false), do: {:ok, "false"}
  def encode(true),  do: {:ok, "true"}
  def encode(atom) when is_atom(atom), do: Atom.to_string(atom) |> JSON.Encoder.encode

  def typeof(boolean) when is_boolean(boolean), do: :boolean
  def typeof(nil), do: :null
  def typeof(atom) when is_atom(atom), do: :string
end

defimpl JSON.Encoder, for: BitString do
  #32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  def encode(bitstring), do: {:ok, <<?">> <> encode_binary_recursive(bitstring, []) <> <<?">>}

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
  defp encode_binary_character(?\\,  acc),  do: [?\\, ?\\ | acc]
  defp encode_binary_character(char, acc) when is_number(char) and char < @acii_space do
    encode_hexadecimal_unicode_control_character(char, [?u,  ?\\ | acc])
  end

  #anything else besides these control characters, just let it through
  defp encode_binary_character(char, acc) when is_number(char), do: [ char | acc ]

  defp encode_hexadecimal_unicode_control_character(char, acc) when is_number(char) do
    [Integer.to_char_list(char, 16) |> zeropad_hexadecimal_unicode_control_character |> Enum.reverse | acc]
  end

  defp zeropad_hexadecimal_unicode_control_character([a, b, c]), do: [?0,  a,  b, c]
  defp zeropad_hexadecimal_unicode_control_character([a, b]),    do: [?0, ?0,  a, b]
  defp zeropad_hexadecimal_unicode_control_character([a]),       do: [?0, ?0, ?0, a]
  defp zeropad_hexadecimal_unicode_control_character(iolist) when is_list(iolist), do: iolist

  def typeof(_), do: :string
end

defimpl JSON.Encoder, for: Record do
  def encode(record), do: record.to_keywords |> JSON.Encoder.Helpers.dict_encode
  def typeof(_), do: :object
end

# Encodes maps into object
# > {:ok, "{\"a\":1,\"b\":2}"} = JSON.encode(%{a: 1, b: 2})
defimpl JSON.Encoder, for: Map do
  def encode(map), do: map |> JSON.Encoder.Helpers.dict_encode
  def typeof(_), do: :object
end

#TODO: maybe this should return the result of "inspect" ?
defimpl JSON.Encoder, for: Any do
  @any_encode "[Elixir.Any]"

  def encode(%{} = struct) do
    JSON.Encoder.Helpers.dict_encode(Map.to_list(struct))
  end

  def encode(_), do: JSON.Encoder.encode(@any_encode)

  def typeof(struct) when is_map(struct), do: :object
  def typeof(_), do: JSON.Encoder.typeof(@any_encode)
end

defmodule JSON.Encoder.Helpers do
  @moduledoc """
  Helper functions for writing JSON.Encoder instances.
  """

  @doc """
  Given an enumerable encode the enumerable as an array.
  """
  def enum_encode(coll) do
    {:ok, "[" <> Enum.map_join(coll, ",", &encode_item(&1)) <> "]"}
  end

  @doc """
  Given an enumerable that yields tuples of `{key, value}` encode the enumerable
  as an object.
  """
  def dict_encode(coll) do
     {:ok, "{" <> Enum.map_join(coll, ",", fn {key, object} -> encode_item(key) <> ":" <>  encode_item(object) end) <> "}"}
  end

  defp encode_item(item) do
    encode_result = JSON.Encoder.encode(item)
    case encode_result do
      {:ok, encoded_item} -> encoded_item
      _ -> encode_result #propagate error, will trigger error in map_join
    end
  end
end
