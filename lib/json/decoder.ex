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

defmodule JSON.Decoder.DefaultImplementations do
  require Logger
  import JSON.Logger

  defimpl JSON.Decoder, for: BitString do
    @moduledoc """
    JSON Decoder implementation for BitString values
    """

    alias JSON.Parser, as: Parser
    alias Parser.Record.Chunk, as: ParserChunk

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
      log(:debug, fn -> "#{__MODULE__}.decode(#{inspect(bitstring)}) starting..." end)

      bitstring
      |> String.trim()
      |> Parser.parse()
      |> case do
        {:error, error_info} ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(bitstring)}} failed with errror: #{
              inspect(error_info)
            }"
          )

          {:error, error_info}

        {:ok, value, rest} ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(bitstring)}) trimming remainder of JSON payload #{
              inspect(rest)
            }..."
          )

          rest
          |> String.trim()
          |> case do
            <<>> ->
              Logger.debug(
                "#{__MODULE__}.decode(#{inspect(bitstring)}) successfully trimmed remainder JSON payload!"
              )

              Logger.debug(
                "#{__MODULE__}.decode(#{inspect(bitstring)}) returning {:ok. #{inspect(value)}}"
              )

              {:ok, value}

            rest ->
              Logger.error(
                "#{__MODULE__}.decode(#{inspect(bitstring)}} failed consume entire buffer: #{rest}"
              )

              {:error, {:unexpected_token, rest}}
          end

        stream = %Stream{} ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(bitstring)}} received stream #{inspect(stream)}"
          )

          run = Enum.to_list(stream)
          Logger.debug("#{__MODULE__}.decode(#{inspect(bitstring)}} run result = #{inspect(run)}")

          err = {:error, :stream_not_implemented}
          Logger.debug("#{__MODULE__}.decode(#{inspect(bitstring)}) returning #{inspect(err)}")
          err

        other ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(bitstring)}) received unexpected result from parse: #{
              inspect(other)
            }"
          )

          err = {:error, {:unexpected_token, other}}
          Logger.debug("#{__MODULE__}.decode(#{inspect(bitstring)}) returning #{inspect(err)}")
          err
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
      charlist
      |> to_string()
      |> Decoder.decode()
      |> case do
        {:ok, value} ->
          {:ok, value}

        {:error, error_info} when is_binary(error_info) ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(charlist)}} failed with errror: #{inspect(error_info)}"
          )

          {:error, error_info |> to_charlist()}

        {:error, {:unexpected_token, bin}} when is_binary(bin) ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(charlist)}} failed with errror: #{inspect(bin)}"
          )

          {:error, {:unexpected_token, bin |> to_charlist()}}

        e = {:error, error_info} ->
          Logger.debug(
            "#{__MODULE__}.decode(#{inspect(charlist)}} failed with errror: #{inspect(e)}"
          )

          {:error, error_info}
      end
    end
  end
end
