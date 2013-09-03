defmodule JSON.Decode do
  defmodule Error, do: defexception([message: "Invalid JSON - unknown error"])
  defmodule UnexpectedEndOfBufferError, do: defexception([message: "Invalid JSON - unexpected end of buffer"])
  defmodule UnexpectedTokenError do
    defexception [token: nil]
    def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
  end


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
