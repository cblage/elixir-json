defmodule JSON.Decoder.Error do
  defexception [message: "Invalid JSON - unknown error"]
end

defmodule JSON.Decoder.UnexpectedEndOfBufferError do
  defexception [message: "Invalid JSON - unexpected end of buffer"]
end

defmodule JSON.Decoder.UnexpectedTokenError do
  defexception [token: nil]

  def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
end

defprotocol JSON.Decoder do
  @moduledoc """
  Defines the protocol required for converting raw JSON into Elixir terms
  """

  @doc """
  Returns an atom and an Elixir term
  """
  @spec decode(any) :: { atom, term }
  def decode(bitstring_or_char_list)
end

defimpl JSON.Decoder, for: BitString do
  def decode(bitstring) do
    case JSON.Parser.Bitstring.trim(bitstring)
          |> JSON.Parser.Bitstring.parse
    do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest }   ->
        case JSON.Parser.Bitstring.trim(rest) do
          << >> -> { :ok, value }
          _     -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end

defimpl JSON.Decoder, for: List do
  def decode(charlist) do
    case JSON.Parser.Charlist.trim(charlist)
          |> JSON.Parser.Charlist.parse
    do
      { :error, error_info } -> { :error, error_info }
      { :ok, value, rest }   ->
        case JSON.Parser.Charlist.trim(rest) do
          [] -> { :ok, value }
          _  -> { :error, { :unexpected_token, rest } }
        end
    end
  end
end
