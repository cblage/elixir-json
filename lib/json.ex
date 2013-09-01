defmodule JSON do

  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.encode([result: "this will be a elixir result"])
      {:ok, "{\\\"result\\\":\\\"this will be a elixir result\\\"}"}

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

      iex> JSON.decode("{\\\"result\\\":\\\"this will be a elixir result\\\"}")
      {:ok, HashDict.new [{"result", "this will be a elixir result"}]}
  """
  @spec decode(bitstring) :: {atom, term}
  @spec decode(char_list) :: {atom, term}
  def decode(string), do: JSON.Decode.from_json(string)
  
  @spec decode!(bitstring) :: term
  @spec decode!(char_list) :: term
  def decode!(bitstring) do
    case decode(bitstring) do
      { :ok, value } -> value
      { :error, {:unexpected_token, tok } } -> raise JSON.Decode.UnexpectedTokenError, token: tok
      { :error, :unexpected_end_of_buffer } -> raise JSON.Decode.UnexpectedEndOfBufferError
      _ -> raise JSON.Decode.Error
    end
  end
end
