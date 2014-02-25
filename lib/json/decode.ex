defexception JSON.Decode.Error, message: "Invalid JSON - unknown error"

defexception JSON.Decode.UnexpectedTokenError, token: nil do
  def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
end

defexception JSON.Decode.UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"


defprotocol JSON.Decode do
  @moduledoc """
  Defines the protocol required for converting raw JSON into Elixir terms
  """


  @doc """
  Returns an atom and an Elixir term
  """
  def from_json(bitstring_or_char_list)

end

defimpl JSON.Decode, for: BitString do
  def from_json(bitstring) do
    case JSON.Parse.Bitstring.Whitespace.consume(bitstring) |> JSON.Parse.Bitstring.Value.consume do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest } ->
        case JSON.Parse.Bitstring.Whitespace.consume(rest) do
          << >> -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end

defimpl JSON.Decode, for: List do
  def from_json(charlist) do
    case JSON.Parse.Charlist.Whitespace.consume(charlist) |> JSON.Parse.Charlist.Value.consume do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest } ->
        case JSON.Parse.Charlist.Whitespace.consume(rest) do
          [] -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end
