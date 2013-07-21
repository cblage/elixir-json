defmodule JSON.Decode do
  defexception UnexpectedTokenError, token: nil do
    def message(exception) do
      "Invalid JSON - unexpected token >>#{exception.token}<<"
    end
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"

  def from_json("[]") do
    []
  end

  def from_json("{}") do
    HashDict.new
  end

  def from_json(<< ?", rest :: binary >>) do
    accept_string(rest, [])
  end

  def from_json(<< m, rest :: binary >>) when m in ?0..?9 do
    accept_number m - ?0, rest
  end

  defp accept_number(n, << m, rest :: binary >>) when m in ?0..?9 do
    accept_number(n * 10 + m - ?0, rest)
  end

  defp accept_number(n, <<>>) do
    n
  end

  #Accepts anything considered a root token (object or array for now)
  defp accept_root(bitstring) do
    {root, remaining_bitstring} = String.lstrip(bitstring) |> process_root_token

    #remaining_bitstring should be empty due to being in the root context otherwise this is invalid json
    unless "" === String.strip(remaining_bitstring) do
      raise UnexpectedTokenError, token: remaining_bitstring
    end

    root
  end

  defp process_root_token(<< ?{ , tail :: binary >>) do
    accept_object(tail)
  end

  defp process_root_token(<< ?[ , tail :: binary >>) do
    accept_list(tail)
  end

  defp process_root_token(token) when is_bitstring(token) do
    raise UnexpectedTokenError, token: token
  end

  defp accept_object(bitstring) when is_bitstring(bitstring) do
    raise "not implemented"
  end

  defp accept_list(bitstring) when is_bitstring(bitstring) do
    raise "not implemented"
  end

  # Stop condition for proper end of string
  defp accept_string(<< ?" >>, accumulator) do
    to_binary(Enum.reverse(accumulator))
  end

  # Never found a closing ?"
  defp accept_string(<<>>, _) do
    raise UnexpectedEndOfBufferError
  end

  defp accept_string(<< x, rest :: binary >>, accumulator) do
    accept_string(rest, [ x | accumulator ])
  end
end
