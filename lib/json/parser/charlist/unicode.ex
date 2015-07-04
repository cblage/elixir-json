defmodule JSON.Parser.Charlist.Unicode do
  @doc """
  parses a valid chain of escaped unicode and returns the string representation,
  plus the remainder of the string

  ## Examples

      iex> JSON.Unicode.Charlist.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Unicode.Charlist.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Unicode.Charlist.parse '-hello'
      {:error, {:unexpected_token, '-hello'} }
  """
  def parse([ ]),  do:  { :error, :unexpected_end_of_buffer }
  def parse(json), do:  { :error, { :unexpected_token, json } }

end
