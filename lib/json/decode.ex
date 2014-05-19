
defmodule JSON.Decode.Error, do: defexception([message: "Invalid JSON - unknown error"])
defmodule JSON.Decode.UnexpectedEndOfBufferError, do: defexception([message: "Invalid JSON - unexpected end of buffer"])
defmodule JSON.Decode.UnexpectedTokenError do
  defexception [token: nil]
  def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
end

defprotocol JSON.Decode do
  @moduledoc """
  Defines the protocol required for converting raw JSON into Elixir terms
  """

  @doc """
  Returns an atom and an Elixir term
  """
  @spec from_json(any, JSON.Collector) :: { atom, term }
  def from_json(bitstring_or_char_list, collector)

end

defimpl JSON.Decode, for: BitString do
  def from_json(bitstring, collector) do
    case JSON.Parse.Bitstring.Whitespace.consume(bitstring)
          |> JSON.Parse.Bitstring.Value.consume(collector)
    do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest }   ->
        case JSON.Parse.Bitstring.Whitespace.consume(rest) do
          << >> -> { :ok, value }
          _     -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end

defimpl JSON.Decode, for: List do
  def from_json(charlist, collector) do
    case JSON.Parse.Charlist.Whitespace.consume(charlist)
          |> JSON.Parse.Charlist.Value.consume(collector)
    do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest }   ->
        case JSON.Parse.Charlist.Whitespace.consume(rest) do
          [] -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end
