defmodule JSON.Parser.Array do
  @moduledoc """
  Implements a JSON Array Parser for Bitstring values
  """

  alias JSON.Parser, as: Parser

  require Logger
  import JSON.Logger

  @doc """
  parses a valid JSON array value, returns its elixir list representation

  ## Examples

      iex> JSON.Parser.Array.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Array.parse "[1, 2 "
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Array.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Parser.Array.parse "[] lala"
      {:ok, [], " lala"}

      iex> JSON.Parser.Array.parse "[]"
      {:ok, [], ""}

      iex> JSON.Parser.Array.parse "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:ok, ["foo", 1, 2, 1.5], " lala"}
  """
  def parse(<<?[, rest::binary>>) do
    log(:debug, fn ->
      "#{__MODULE__}.parse(#{inspect(rest)}) trimming string and the calling parse_array_contents()"
    end)

    rest |> String.trim() |> parse_array_contents()
  end

  def parse(<<>>) do
    log(:debug, fn -> "#{__MODULE__}.parse(<<>>) unexpected end of buffer." end)
    {:error, :unexpected_end_of_buffer}
  end

  def parse(json) do
    log(:debug, fn -> "#{__MODULE__}.parse(<<>>) unexpected token: #{inspect(json)}" end)
    {:error, {:unexpected_token, json}}
  end

  # begin parse array
  defp parse_array_contents(json) when is_binary(json) do
    log(:debug, fn ->
      "#{__MODULE__}.parse_array_contents(#{inspect(json)}) beginning to parse array contents..."
    end)

    parse_array_contents([], json)
  end

  # stop condition
  defp parse_array_contents(acc, <<?], rest::binary>>) do
    log(:debug, fn ->
      "#{__MODULE__}.parse_array_contents(#{inspect(acc)}, #{inspect(rest)}) finished parsing array contents."
    end)

    {:ok, Enum.reverse(acc), rest}
  end

  # error condition
  defp parse_array_contents(_, <<>>) do
    log(:debug, fn ->
      "#{__MODULE__}.parse_array_contents(acc, <<>>) unexpected end of buffer."
    end)

    {:error, :unexpected_end_of_buffer}
  end

  defp parse_array_contents(acc, json) do
    json
    |> String.trim()
    |> Parser.parse()
    |> case do
      {:error, error_info} ->
        log(:debug, fn ->
          "#{__MODULE__}.parse_array_contents(#{inspect(acc)}, #{inspect(json)}) generated an error: #{
            inspect(error_info)
          }"
        end)

        {:error, error_info}

      {:ok, value, after_value} ->
        log(:debug, fn ->
          "#{__MODULE__}.parse_array_contents(acc, json) sucessfully parsed value `#{
            inspect(value)
          }`, with
        after_value=#{inspect(after_value)}"
        end)

        after_value
        |> String.trim()
        |> case do
          <<?,, after_comma::binary>> ->
            trimmed = String.trim(after_comma)

            log(:debug, fn ->
              "#{__MODULE__}.parse_array_contents(acc, json) found a comma, continuing parsing of #{
                inspect(trimmed)
              }"
            end)

            parse_array_contents([value | acc], trimmed)

          rest ->
            log(:debug, fn ->
              "#{__MODULE__}.parse_array_contents(acc, json) continuing parsing of #{
                inspect(rest)
              }"
            end)

            parse_array_contents([value | acc], rest)
        end
    end
  end
end
