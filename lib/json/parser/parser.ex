defmodule JSON.Parser do
  @moduledoc """
  Implements a JSON Parser for Bitstring values
  """

  alias JSON.Parser, as: Parser
  alias Parser.Array, as: ArrayParser
  alias Parser.Number, as: NumberParser
  alias Parser.Object, as: ObjectParser
  alias Parser.String, as: StringParser

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
  def parse(<<?[, _::binary>> = bin), do: ArrayParser.parse(bin)
  def parse(<<?{, _::binary>> = bin), do: ObjectParser.parse(bin)
  def parse(<<?", _::binary>> = bin), do: StringParser.parse(bin)

  def parse(<<?-, number::utf8, _::binary>> = bin) when number in ?0..?9 do
    NumberParser.parse(bin)
  end

  def parse(<<number::utf8, _::binary>> = bin) when number in ?0..?9 do
    NumberParser.parse(bin)
  end

  def parse(<<?n, ?u, ?l, ?l, rest::binary>>), do: {:ok, nil, rest}
  def parse(<<?t, ?r, ?u, ?e, rest::binary>>), do: {:ok, true, rest}
  def parse(<<?f, ?a, ?l, ?s, ?e, rest::binary>>), do: {:ok, false, rest}

  def parse(<<>>), do: {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, {:unexpected_token, json}}

  @doc """
  parses valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parser.trim ""
      ""

      iex> JSON.Parser.trim "xkcd"
      "xkcd"

      iex> JSON.Parser.trim "  \\t\\r lalala "
      "lalala "

      iex> JSON.Parser.trim " \\n\\t\\n fooo \\u00dflalalal "
      "fooo \\u00dflalalal "
  """
  def trim(bitstring) when is_binary(bitstring) do
    case bitstring do
      # 32 = ascii space, clearer than using "? ", I think
      <<32::utf8, rest::binary>> ->
        trim(rest)

      <<?\t::utf8, rest::binary>> ->
        trim(rest)

      <<?\r::utf8, rest::binary>> ->
        trim(rest)

      <<?\n::utf8, rest::binary>> ->
        trim(rest)

      _ ->
        bitstring
    end
  end
end
