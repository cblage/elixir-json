defmodule JSON.Decoder.Error do
  @moduledoc """
  Thrown when an unknown decoder error happens
  """
  defexception [message: "Invalid JSON - unknown error"]

  @doc """
    Invalid JSON
  """
  @spec message(__MODULE__.t) :: String.t
  def message(exception)

  @doc """
    Invalid JSON
  """
  @spec exception(term) :: __MODULE__.t
  def exception(term)
end

defmodule JSON.Decoder.UnexpectedEndOfBufferError do
  @moduledoc """
  Thrown when the json payload is incomplete
  """
  defexception [message: "Invalid JSON - unexpected end of buffer"]

  @doc """
    Invalid JSON - unexpected end of buffer
  """
  @spec message(__MODULE__.t) :: String.t
  def message(exception)

  @doc """
    Invalid JSON - unexpected end of buffer
  """
  @spec exception(term) :: __MODULE__.t
  def exception(term)
end

defmodule JSON.Decoder.UnexpectedTokenError do
  @moduledoc """
  Thrown when the json payload is invalid
  """
  defexception [token: nil]

  @doc """
    Invalid JSON - Unexpected token
  """
  @spec message(__MODULE__.t) :: String.t
  def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"

  @doc """
    Invalid JSON - unexpected token
  """
  @spec exception(term) :: __MODULE__.t
  def exception(term)
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

  alias JSON.Parser.Bitstring, as: BitstringParser

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
    |> BitstringParser.trim
    |> BitstringParser.parse
    |> case do
      {:error, error_info} -> {:error, error_info}
      {:ok, value, rest}   ->
        case BitstringParser.trim(rest) do
          << >> -> {:ok, value}
          _     -> {:error, {:unexpected_token, rest}}
        end
    end
  end
end

defimpl JSON.Decoder, for: List do
  @moduledoc """
  JSON Decoder implementation for Charlist values
  """
  alias JSON.Parser.Charlist, as: CharlistParser

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
    charlist
    |> CharlistParser.trim
    |> CharlistParser.parse
    |> case do
      {:error, error_info} -> {:error, error_info}
      {:ok, value, rest} ->
        case CharlistParser.trim(rest) do
          [] -> {:ok, value}
          _  -> {:error, {:unexpected_token, rest}}
        end
    end
  end
end
