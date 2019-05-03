defmodule JSON.Encoder.Helpers do
  @moduledoc """
  Helper functions for JSON.Encoder
  """

  alias JSON.Encoder, as: Encoder

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
    case Encoder.encode(item) do
      {:ok, encoded_item} -> encoded_item
      # propagate error, will trigger error in map_join
      err -> err
    end
  end
end
