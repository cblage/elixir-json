defmodule JSON.Decoder.Error do
  @moduledoc """
  Thrown when an unknown decoder error happens
  """
  defexception message: "Invalid JSON - unknown error"
end

defmodule JSON.Decoder.UnexpectedEndOfBufferError do
  @moduledoc """
  Thrown when the json payload is incomplete
  """
  defexception message: "Invalid JSON - unexpected end of buffer"
end

defmodule JSON.Decoder.UnexpectedTokenError do
  @moduledoc """
  Thrown when the json payload is invalid
  """
  defexception token: nil

  @doc """
    Invalid JSON - Unexpected token
  """
  def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
end

defprotocol JSON.Decoder do
  @moduledoc """
  Defines the protocol required for converting raw JSON into Elixir terms
  """

  @doc """
  Returns an atom and an Elixir term
  """
  @spec decode(any) :: {atom, term}
  def decode(bitstring_or_char_list)
end

defimpl JSON.Decoder, for: BitString do
  @moduledoc """
  JSON Decoder implementation for BitString values
  """

  alias JSON.Parser, as: Parser

  @doc """
  decodes json in BitString format

  ## Examples

      iex> JSON.Decoder.decode ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Decoder.decode "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Decoder.decode "-hello"
      {:error, {:unexpected_token, "-hello"}}

  """
  def decode(bitstring) do
    bitstring
    |> Parser.trim()
    |> Parser.parse()
    |> case do
      {:error, error_info} ->
        {:error, error_info}

      {:ok, value, rest} ->
        case Parser.trim(rest) do
          <<>> -> {:ok, value}
          _ -> {:error, {:unexpected_token, rest}}
        end
    end
  end
end

defimpl JSON.Decoder, for: List do
  @moduledoc """
  JSON Decoder implementation for Charlist values
  """

  alias JSON.Decoder, as: Decoder

  @doc """
  decodes json in BitString format

  ## Examples

      iex> JSON.Decoder.decode ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Decoder.decode "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Decoder.decode "-hello"
      {:error, {:unexpected_token, "-hello"}}

  """
  def decode(charlist) do
    charlist |>
      to_string() |>
      Decoder.decode() |>
      case do
        {:error, {:unexpected_token, rest}} -> {:error, {:unexpected_token, rest |> to_charlist()}}
        ok -> ok
      end
  end
end
