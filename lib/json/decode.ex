defmodule JSON.Decode do
  defmodule Error, do: defexception([message: "Invalid JSON - unknown error"])
  defmodule UnexpectedEndOfBufferError, do: defexception([message: "Invalid JSON - unexpected end of buffer"])
  defmodule UnexpectedTokenError do
    defexception [token: nil]
    def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
  end


  def from_json(bitstring) when is_binary(bitstring) do
    case bitstring_to_list(bitstring) |> from_json do
      { :ok, value } -> { :ok, value }
      { :error, error_info } ->
        case error_info do
          { :unexpected_token, tok } -> { :error, { :unexpected_token, iolist_to_binary(tok) }}
          _ -> { :error, error_info }
        end
    end
  end

  def from_json(iolist) when is_list(iolist) do
    case JSON.Parse.consume_whitespace(iolist) |> JSON.Parse.Value.consume do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest } ->
        case JSON.Parse.consume_whitespace(rest) do
          [] -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end
