defmodule JSON do
  @moduledoc """
  Provides a RFC 7159, ECMA 404, and JSONTestSuite compliant JSON Encoder / Decoder
  """

  require Logger

  import JSON.Logger

  alias JSON.Decoder
  alias JSON.Encoder

  @vsn "2.0.0-SNAPSHOT"

  @doc """
  Returns a JSON string representation of the Elixir term

  ## Examples

      iex> JSON.encode([result: "this will be a JSON result"])
      {:ok, "{\\\"result\\\":\\\"this will be a JSON result\\\"}"}

  """
  @spec encode(term) :: {atom, bitstring}
  defdelegate encode(term), to: Encoder

  @doc """
  Returns a JSON string representation of the Elixir term, raises errors when something bad happens

  ## Examples

      iex> JSON.encode!([result: "this will be a JSON result"])
      "{\\\"result\\\":\\\"this will be a JSON result\\\"}"

  """
  @spec encode!(term) :: bitstring
  def encode!(term) do
    term
    |> Encoder.encode()
    |> case do
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

  # defdelegate decode(bitstring_or_char_list), to: Decoder

  # TODO: use new logging
  def decode(bitstring_or_char_list) do
    bitstring_or_char_list
    |> Decoder.decode()
    |> case do
      res = {:ok, _} ->
        Logger.debug(
          "#{__MODULE__}.decode(#{inspect(bitstring_or_char_list)}} was sucesfull: #{inspect(res)}"
        )

        res

      e = {:error, {:unexpected_token, tok}} ->
        Logger.debug(
          "#{__MODULE__}.decode!(#{inspect(bitstring_or_char_list)}} unexpected token #{tok}"
        )

        e

      e = {:error, :unexpected_end_of_buffer} ->
        Logger.debug("#{__MODULE__}.decode!(#{inspect(bitstring_or_char_list)}} end of buffer")
        e

      e ->
        Logger.debug(
          "#{__MODULE__}.decode!(#{inspect(bitstring_or_char_list)}} an unknown problem occurred #{
            inspect(e)
          }"
        )

        e
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
    bitstring_or_char_list
    |> decode()
    |> case do
      {:ok, value} ->
        value

      {:error, {:unexpected_token, tok}} ->
        log(:debug, fn ->
          "#{__MODULE__}.decode!(#{inspect(bitstring_or_char_list)}} unexpected token #{tok}"
        end)

        raise JSON.Decoder.UnexpectedTokenError, token: tok

      {:error, :unexpected_end_of_buffer} ->
        log(:debug, fn ->
          "#{__MODULE__}.decode!(#{inspect(bitstring_or_char_list)}} end of buffer"
        end)

        raise JSON.Decoder.UnexpectedEndOfBufferError

      e ->
        log(:debug, fn ->
          "#{__MODULE__}.decode!(#{inspect(bitstring_or_char_list)}} an unknown problem occurred #{
            inspect(e)
          }"
        end)

        raise JSON.Decoder.Error
    end
  end
end
