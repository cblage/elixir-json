defmodule JSON do
  @moduledoc """
  Provides a RFC 7159, ECMA 404, and JSONTestSuite compliant JSON Encoder / Decoder
  """

  require Logger
  import JSON.Logger

  alias JSON.Encoder, as: Encoder
  alias JSON.Decoder, as: Decoder

  @vsn "1.0.2"

  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.encode([result: "this will be a JSON result"])
      {:ok, "{\\\"result\\\":\\\"this will be a JSON result\\\"}"}

  """
  @spec encode(term) :: {atom, bitstring}
  def encode(term), do: Encoder.encode(term)

  @doc """
  Returns a JSON string representation of the Elixir term, raises errors when something bad happens

  ## Examples

      iex> JSON.encode!([result: "this will be a JSON result"])
      "{\\\"result\\\":\\\"this will be a JSON result\\\"}"

  """
  @spec encode!(term) :: bitstring
  def encode!(term) do
    case Encoder.encode(term) do
      {:ok, value} -> value
      {:error, error_info} -> raise JSON.Encoder.Error, error_info: error_info
      _ -> raise JSON.Encoder.Error
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
    bitstring_or_char_list |>
      Decoder.decode() |>
      case  do
       res = {:ok, _} ->
        log(:debug, fn -> "#{__MODULE__}.decode(#{inspect bitstring_or_char_list}} was sucesfull: #{inspect res}" end)
         res
       e = {:error, {:unexpected_token, tok}} ->
         log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} unexpected token #{tok}" end)
         e
       e = {:error, :unexpected_end_of_buffer} ->
         log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} end of buffer" end)
         e
       e ->
         log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} an unknown problem occurred #{inspect e}" end)
     end
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
    case Decoder.decode(bitstring_or_char_list) do
      {:ok, value} ->
        log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} was sucesfull: #{inspect value}" end)
        value
      {:error, {:unexpected_token, tok}} ->
        log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} unexpected token #{tok}" end)
        raise JSON.Decoder.UnexpectedTokenError, token: tok
      {:error, :unexpected_end_of_buffer} ->
        log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} end of buffer" end)
        raise JSON.Decoder.UnexpectedEndOfBufferError
      e ->
        log(:debug, fn -> "#{__MODULE__}.decode!(#{inspect bitstring_or_char_list}} an unknown problem occurred #{inspect e}" end)
    end
  end
end
