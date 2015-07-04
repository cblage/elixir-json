defmodule JSON.Parser.Bitstring.Unicode do
  @doc """
  parses a valid chain of escaped unicode and returns the string representation,
  plus the remainder of the string

  ## Examples

      iex> JSON.Parser.Bitstring.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Bitstring.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parser.Bitstring.parse "-hello"
      {:error, {:unexpected_token, "-hello"} }

  """
  def parse(<< >>), do:  {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, { :unexpected_token, json }}
end
