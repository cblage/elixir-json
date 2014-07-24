defmodule JSON.Parse.Bitstring do
  @doc """
  Consumes a valid JSON value, returns its elixir representation

  ## Examples

      iex> JSON.Parse.Bitstring.consume ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Bitstring.consume "face0ff"
      {:error, {:unexpected_token, "face0ff"} }

      iex> JSON.Parse.Bitstring.consume "-hello"
      {:error, {:unexpected_token, "-hello"} }

      iex> JSON.Parse.Bitstring.consume "129245"
      {:ok, 129245, "" }

      iex> JSON.Parse.Bitstring.consume "7.something"
      {:ok, 7, ".something" }

      iex> JSON.Parse.Bitstring.consume "-88.22suffix"
      {:ok, -88.22, "suffix" }

      iex> JSON.Parse.Bitstring.consume "-12e4and then some"
      {:ok, -1.2e+5, "and then some" }

      iex> JSON.Parse.Bitstring.consume "7842490016E-12-and more"
      {:ok, 7.842490016e-3, "-and more" }

      iex> JSON.Parse.Bitstring.consume "null"
      {:ok, nil, ""}

      iex> JSON.Parse.Bitstring.consume "false"
      {:ok, false, "" }

      iex> JSON.Parse.Bitstring.consume "true"
      {:ok, true, "" }

      iex> JSON.Parse.Bitstring.consume "\\\"7.something\\\""
      {:ok, "7.something", "" }

      iex> JSON.Parse.Bitstring.consume "\\\"-88.22suffix\\\" foo bar"
      {:ok, "-88.22suffix", " foo bar" }

      iex> JSON.Parse.Bitstring.consume "\\\"star -> \\\\u272d <- star\\\""
      {:ok, "star -> ✭ <- star", "" }

      iex> JSON.Parse.Bitstring.consume "[]"
      {:ok, [], "" }

      iex> JSON.Parse.Bitstring.consume "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:ok, ["foo", 1, 2, 1.5], " lala" }

      iex> JSON.Parse.Bitstring.consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), " lalal"}
  """
  def consume(<< ?[, _ :: binary >> = bin), do: JSON.Parse.Bitstring.Array.consume(bin)
  def consume(<< ?{, _ :: binary >> = bin), do: JSON.Parse.Bitstring.Object.consume(bin)
  def consume(<< ?", _ :: binary >> = bin), do: JSON.Parse.Bitstring.String.consume(bin)

  def consume(<< ?- , number :: utf8, _ :: binary >> = bin) when number in ?0..?9 do
    JSON.Parse.Bitstring.Number.consume(bin)
  end

  def consume(<< number :: utf8, _ :: binary >> = bin) when number in ?0..?9 do
    JSON.Parse.Bitstring.Number.consume(bin)
  end

  def consume(<< ?n, ?u, ?l, ?l, rest :: binary >>), do: { :ok, nil,   rest }
  def consume(<< ?t, ?r, ?u, ?e, rest :: binary >>), do: { :ok, true,  rest }
  def consume(<< ?f, ?a, ?l, ?s, ?e, rest :: binary >>), do: { :ok, false, rest }

  def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
  def consume(json), do: {:error, { :unexpected_token, json }}

  @doc """
  Consumes valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parse.Bitstring.trim ""
      ""

      iex> JSON.Parse.Bitstring.trim "xkcd"
      "xkcd"

      iex> JSON.Parse.Bitstring.trim "  \\t\\r lalala "
      "lalala "

      iex> JSON.Parse.Bitstring.trim " \\n\\t\\n fooo \\u00dflalalal "
      "fooo \\u00dflalalal "
  """
  def trim(bitstring) when is_binary(bitstring) do
    case bitstring do
      #32 = ascii space, clearer than using "? ", I think
      << 32  :: utf8, rest :: binary >> -> trim rest
      << ?\t :: utf8, rest :: binary >> -> trim rest
      << ?\r :: utf8, rest :: binary >> -> trim rest
      << ?\n :: utf8, rest :: binary >> -> trim rest
      _ -> bitstring
    end
  end
end
