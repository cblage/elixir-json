defmodule JSON.Decode do
  defexception Error, message: "Invalid JSON - unknown error"

  defexception UnexpectedTokenError, token: nil do
    def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
  end

  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"


  def from_bitstring(bitstring) when is_bitstring(bitstring) do
    case JSON.Parse.bitstring_consume_whitespace(bitstring) |> JSON.Parse.Value.bitstring_consume do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest } ->
        case JSON.Parse.bitstring_consume_whitespace(rest) do
          << >> -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end

  def from_charlist(charlist) when is_list(charlist) do 
    case JSON.Parse.charlist_consume_whitespace(charlist) |> JSON.Parse.Value.charlist_consume do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest } ->
        case JSON.Parse.charlist_consume_whitespace(rest) do
          [] -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end
