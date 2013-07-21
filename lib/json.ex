defmodule JSON do

  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.encode([result: "this will be a elixir result"])
      "{\"result\":\"this will be a elixir result\"}"

  """
  @spec encode(term) :: bitstring
  def encode(term) do
    JSON.Encode.to_json(term)
  end


  @doc """
  Converts a valid JSON string into an Elixir term

  ## Examples

      iex> JSON.decode("{\"result\":\"this will be a elixir result\"}")
      {:ok, [result: "this will be a elixir result"]}

  """
  @spec decode(bitstring) :: {atom, term}
  def decode(bitstring) do
     try do
      {:ok, JSON.decode!(bitstring)}
    rescue
      error -> {:error, error}
    end
  end

  @spec decode!(bitstring) :: term
  def decode!(item) do
    JSON.Decode.from_json(item)
  end

end
