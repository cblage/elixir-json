defmodule JSON.Encoder.Error do
  @moduledoc """
  Thrown when an encoder error happens
  """
  defexception error_info: nil

  @doc """
    Invalid Term
  """
  def message(exception) do
    error_message = "An error occurred while encoding the JSON object"

    if nil != exception.error_info do
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
      iex> JSON.Encoder.encode({1, :two, "three"})
      {:ok, "[1,\\\"two\\\",\\\"three\\\"]"}

      iex> JSON.Encoder.encode([result: "this will be a elixir result"])
      {:ok, "{\\\"result\\\":\\\"this will be a elixir result\\\"}"}

      iex> JSON.Encoder.encode(%{a: 1, b: 2})
      {:ok, "{\\\"a\\\":1,\\\"b\\\":2}"}
  """
  @spec encode(tuple|HashDict.t|list|integer|float|map|list|atom|term) :: {atom, bitstring}
  def encode(term)

  @doc """
  Returns an atom that reprsents the JSON type for the term

  ## Examples
      iex> JSON.Encoder.typeof(3)
      :number

      iex> JSON.Encoder.typeof({1, :two, "three"})
      :array

      iex> JSON.Encoder.typeof([foo: "this will be a elixir result"])
      :object

      iex> JSON.Encoder.typeof([result: "this will be a elixir result"])
      :object

      iex> JSON.Encoder.typeof(["this will be a elixir result"])
      :array

      iex> JSON.Encoder.typeof([foo: "bar"])
      :object
  """
  @spec typeof(term) :: atom
  def typeof(term)
end

defimpl JSON.Encoder, for: Tuple do
  @doc """
  Encodes an Elixir tuple into a JSON array
  """
  def encode(term), do: term |> Tuple.to_list() |> JSON.Encoder.Helpers.enum_encode()

  @doc """
  Returns an atom that represents the JSON type for the term
  """
  def typeof(_), do: :array
end

defimpl JSON.Encoder, for: HashDict do
  @doc """
  Encodes an Elixir HashDict into a JSON object
  """
  def encode(dict), do: JSON.Encoder.Helpers.dict_encode(dict)

  @doc """
  Returns :object
  """
  def typeof(_), do: :object
end

defimpl JSON.Encoder, for: List do
  @doc """
  Encodes an Elixir List into a JSON array
  """
  def encode([]), do: {:ok, "[]"}

  def encode(list) do
    if Keyword.keyword?(list) do
      JSON.Encoder.Helpers.dict_encode(list)
    else
      JSON.Encoder.Helpers.enum_encode(list)
    end
  end

  @doc """
  Returns an atom that represents the JSON type for the term
  """
  def typeof([]), do: :array

  def typeof(list) do
    if Keyword.keyword?(list) do
      :object
    else
      :array
    end
  end
end

defimpl JSON.Encoder, for: [Integer, Float] do
  @doc """
  Converts Elixir Integer and Floats into JSON Numbers
  """
  # Elixir converts octal, etc into decimal when putting in strings
  def encode(number), do: {:ok, "#{number}"}

  @doc """
  Returns an atom that represents the JSON type for the term
  """
  def typeof(_), do: :number
end

defimpl JSON.Encoder, for: Atom do
  @doc """
  Converts Elixir Atoms into their JSON equivalents
  """
  def encode(nil), do: {:ok, "null"}
  def encode(false), do: {:ok, "false"}
  def encode(true), do: {:ok, "true"}
  def encode(atom) when is_atom(atom), do: atom |> Atom.to_string() |> JSON.Encoder.encode()

  @doc """
  Returns an atom that represents the JSON type for the term
  """
  def typeof(boolean) when is_boolean(boolean), do: :boolean
  def typeof(nil), do: :null
  def typeof(atom) when is_atom(atom), do: :string
end

defimpl JSON.Encoder, for: BitString do
  # 32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  @doc """
  Converts Elixir String into JSON String
  """
  def encode(bitstring), do: {:ok, <<?">> <> encode_binary_recursive(bitstring, []) <> <<?">>}

  defp encode_binary_recursive(<<head::utf8, tail::binary>>, acc) do
    encode_binary_recursive(tail, encode_binary_character(head, acc))
  end

  # stop cond
  defp encode_binary_recursive(<<>>, acc), do: acc |> Enum.reverse() |> to_string

  defp encode_binary_character(?", acc), do: [?", ?\\ | acc]
  defp encode_binary_character(?\b, acc), do: [?b, ?\\ | acc]
  defp encode_binary_character(?\f, acc), do: [?f, ?\\ | acc]
  defp encode_binary_character(?\n, acc), do: [?n, ?\\ | acc]
  defp encode_binary_character(?\r, acc), do: [?r, ?\\ | acc]
  defp encode_binary_character(?\t, acc), do: [?t, ?\\ | acc]
  defp encode_binary_character(?\\, acc), do: [?\\, ?\\ | acc]

  defp encode_binary_character(char, acc) when is_number(char) and char < @acii_space do
    encode_hexadecimal_unicode_control_character(char, [?u, ?\\ | acc])
  end

  # anything else besides these control characters, just let it through
  defp encode_binary_character(char, acc) when is_number(char), do: [char | acc]

  defp encode_hexadecimal_unicode_control_character(char, acc) when is_number(char) do
    [
      char
      |> Integer.to_charlist(16)
      |> zeropad_hexadecimal_unicode_control_character
      |> Enum.reverse()
      | acc
    ]
  end

  defp zeropad_hexadecimal_unicode_control_character([a, b, c]), do: [?0, a, b, c]
  defp zeropad_hexadecimal_unicode_control_character([a, b]), do: [?0, ?0, a, b]
  defp zeropad_hexadecimal_unicode_control_character([a]), do: [?0, ?0, ?0, a]
  defp zeropad_hexadecimal_unicode_control_character(iolist) when is_list(iolist), do: iolist

  @doc """
  Returns an atom that represents the JSON type for the term
  """
  def typeof(_), do: :string
end

defimpl JSON.Encoder, for: Record do
  @doc """
  Encodes elixir records into json objects
  """
  def encode(record), do: record.to_keywords |> JSON.Encoder.Helpers.dict_encode()

  @doc """
  Encodes a record into a JSON object
  """
  def typeof(_), do: :object
end

defimpl JSON.Encoder, for: Map do
  @doc """
  Encodes maps into object
  """
  def encode(map), do: map |> JSON.Encoder.Helpers.dict_encode()

  @doc """
  Returns an atom that represents the JSON type for the term
  """
  def typeof(_), do: :object
end

defimpl JSON.Encoder, for: Any do
  @moduledoc """
  Falllback module for encoding any other values
  """

  @doc """
  Encodes a map into a JSON object
  """
  def encode(%{} = struct) do
    struct
    |> Map.to_list()
    |> JSON.Encoder.Helpers.dict_encode()
  end

  @doc """
  Fallback method
  """
  def encode(x) do
    x
    |> Kernel.inspect()
    |> JSON.Encoder.encode()
  end

  @doc """
  Fallback method
  """
  def typeof(struct) when is_map(struct), do: :object
  def typeof(_), do: :string
end

defmodule JSON.Encoder.Helpers do
  import JSON.Encoder, only: [encode: 1]

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
    {:ok,
     "{" <>
       Enum.map_join(coll, ",", fn {key, object} ->
         encode_item(key) <> ":" <> encode_item(object)
       end) <> "}"}
  end

  defp encode_item(item) do
    case encode(item) do
      {:ok, encoded_item} ->
        encoded_item

      # propagate error, will trigger error in map_join
      err ->
        err
    end
  end
end
