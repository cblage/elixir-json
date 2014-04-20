defmodule JSON do

  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.encode([result: "this will be a JSON result"])
      {:ok, "{\\\"result\\\":\\\"this will be a JSON result\\\"}"}

  """
  @spec encode(term) :: {atom, bitstring}
  def encode(term), do: JSON.Encode.to_json(term)

  @spec encode!(term) :: bitstring
  def encode!(term) do
    case encode(term) do
      { :ok, value }         -> value
      { :error, error_info } -> raise JSON.Encode.Error, error_info: error_info
      _                      -> raise JSON.Encode.Error
    end
  end


  @doc """
  Converts a valid JSON string into an Elixir term

  ## Examples

      iex> JSON.decode("{\\\"result\\\":\\\"this will be an Elixir result\\\"}")
      {:ok, HashDict.new [{"result", "this will be an Elixir result"}]}
  """
  @spec decode(bitstring, JSON.Collector.t) :: {atom, term}
  @spec decode(char_list, JSON.Collector.t) :: {atom, term}
  def decode(bitstring_or_char_list, collector \\ JSON.Collector.new), do: JSON.Decode.from_json(bitstring_or_char_list, collector)
  
  
  @spec decode!(bitstring, JSON.Collector) :: term
  @spec decode!(char_list, JSON.Collector) :: term
  def decode!(bitstring_or_char_list, collector \\ JSON.Collector.new) do
    case decode(bitstring_or_char_list, collector) do
      { :ok, value } -> value
      { :error, {:unexpected_token, tok } } -> raise JSON.Decode.UnexpectedTokenError, token: tok
      { :error, :unexpected_end_of_buffer } -> raise JSON.Decode.UnexpectedEndOfBufferError
      _ -> raise JSON.Decode.Error
    end
  end
end
