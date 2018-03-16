defmodule JSON do
  @moduledoc """
  Provides a RFC 7159, ECMA 404, and JSONTestSuite compliant JSON Encoder / Decoder
  """

  @vsn "1.0.2"

  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.encode([result: "this will be a JSON result"])
      {:ok, "{\\\"result\\\":\\\"this will be a JSON result\\\"}"}

  """
  @spec encode(term) :: {atom, bitstring}
  def encode(term) do
    JSON.Encoder.encode(term)
  end

  @doc """
  Returns a JSON string representation of the Elixir term, raises errors when something bad happens

  ## Examples

      iex> JSON.encode!([result: "this will be a JSON result"])
      "{\\\"result\\\":\\\"this will be a JSON result\\\"}"

  """
  @spec encode!(term) :: bitstring
  def encode!(term) do
    case encode(term) do
      {:ok, value}         -> value
      {:error, error_info} -> raise JSON.Encoder.Error, error_info: error_info
      _                    -> raise JSON.Encoder.Error
    end
  end


  @doc """
  Converts a valid JSON string into an Elixir term

  ## Examples

      iex> JSON.decode("{\\\"result\\\":\\\"this will be an Elixir result\\\"}")
      {:ok, Enum.into([{"result", "this will be an Elixir result"}], Map.new)}
  """
  @spec decode(bitstring) :: {atom, term}
  @spec decode(charlist) :: {atom, term}
  def decode(bitstring_or_char_list) do
    JSON.Decoder.decode(bitstring_or_char_list)
  end

  @doc """
  Converts a valid JSON string into an Elixir term, raises errors when something bad happens

  ## Examples

      iex> JSON.decode!("{\\\"result\\\":\\\"this will be an Elixir result\\\"}")
      Enum.into([{"result", "this will be an Elixir result"}], Map.new)
  """
  @spec decode!(bitstring) :: term
  @spec decode!(charlist) :: term
  def decode!(bitstring_or_char_list) do
    case decode(bitstring_or_char_list) do
      {:ok, value} -> value
      {:error, {:unexpected_token, tok}} -> raise JSON.Decoder.UnexpectedTokenError, token: tok
      {:error, :unexpected_end_of_buffer} -> raise JSON.Decoder.UnexpectedEndOfBufferError
      _ -> raise JSON.Decoder.Error
    end
  end
end
