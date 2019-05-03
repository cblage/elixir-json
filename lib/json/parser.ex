defmodule JSON.Parser do
  @moduledoc """
  Implements a JSON Parser for Bitstring values
  """

  alias JSON.Parser, as: Parser
  alias Parser.Array, as: ArrayParser
  alias Parser.Number, as: NumberParser
  alias Parser.Object, as: ObjectParser
  alias Parser.String, as: StringParser

  require Logger
  import JSON.Logger

  @doc """
  parses a valid JSON value, returns its elixir representation

  ## Examples

      iex> JSON.Parser.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Parser.parse "-hello"
      {:error, {:unexpected_token, "-hello"}}

      iex> JSON.Parser.parse "129245"
      {:ok, 129245, ""}

      iex> JSON.Parser.parse "7.something"
      {:ok, 7, ".something"}

      iex> JSON.Parser.parse "-88.22suffix"
      {:ok, -88.22, "suffix"}

      iex> JSON.Parser.parse "-12e4and then some"
      {:ok, -1.2e+5, "and then some"}

      iex> JSON.Parser.parse "7842490016E-12-and more"
      {:ok, 7.842490016e-3, "-and more"}

      iex> JSON.Parser.parse "null"
      {:ok, nil, ""}

      iex> JSON.Parser.parse "false"
      {:ok, false, ""}

      iex> JSON.Parser.parse "true"
      {:ok, true, ""}

      iex> JSON.Parser.parse "\\\"7.something\\\""
      {:ok, "7.something", ""}

      iex> JSON.Parser.parse "\\\"-88.22suffix\\\" foo bar"
      {:ok, "-88.22suffix", " foo bar"}

      iex> JSON.Parser.parse "\\\"star -> \\\\u272d <- star\\\""
      {:ok, "star -> ✭ <- star", ""}

      iex> JSON.Parser.parse "[]"
      {:ok, [], ""}

      iex> JSON.Parser.parse "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:ok, ["foo", 1, 2, 1.5], " lala"}

      iex> JSON.Parser.parse "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), " lalal"}
  """

  def parse(<<?[, _::binary>> = bin) do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) starting ArrayParser.parse(bin)..." end)
    ArrayParser.parse(bin)
  end

  def parse(<<?{, _::binary>> = bin) do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) starting ObjectParser.parse(bin)..." end)
    ObjectParser.parse(bin)
  end

  def parse(<<?", _::binary>> = bin) do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) starting ArrayParser.parse(bin)..." end)
    StringParser.parse(bin)
  end

  def parse(<<?-, number::utf8, _::binary>> = bin) when number in ?0..?9 do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) starting negative NumberParser.parse(bin)..." end)
    NumberParser.parse(bin)
  end

  def parse(<<number::utf8, _::binary>> = bin) when number in ?0..?9 do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) starting NumberParser.parse(bin)..." end)
    NumberParser.parse(bin)
  end

  def parse(<<?n, ?u, ?l, ?l, rest::binary>>) do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) parsed `null` token." end)
    {:ok, nil, rest}
  end

  def parse(<<?t, ?r, ?u, ?e, rest::binary>>) do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) parsed `true` token." end)
    {:ok, true, rest}
  end

  def parse(<<?f, ?a, ?l, ?s, ?e, rest::binary>>) do
    log(:debug, fn -> "#{__MODULE__}.parse(bin) parsed `false` token." end)
    {:ok, false, rest}
  end

  def parse(<<>>) do
    log(:debug, fn -> "#{__MODULE__}.parse(<<>>) unexpected end of buffer." end)
    {:error, :unexpected_end_of_buffer}
  end

  def parse(json) do
    log(:debug, fn -> "#{__MODULE__}.parse(json) unexpected token: #{inspect(json)}" end)
    {:error, {:unexpected_token, json}}
  end
end
