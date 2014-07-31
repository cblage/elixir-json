defmodule JSON.Parser.Charlist do
  @doc """
  parses a valid JSON value, returns its elixir representation

  ## Examples

      iex> JSON.Parser.Charlist.parse ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Charlist.parse 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parser.Charlist.parse '-hello'
      {:error, {:unexpected_token, '-hello'} }

      iex> JSON.Parser.Charlist.parse '129245'
      {:ok, 129245, '' }

      iex> JSON.Parser.Charlist.parse '7.something'
      {:ok, 7, '.something' }

      iex> JSON.Parser.Charlist.parse '-88.22suffix'
      {:ok, -88.22, 'suffix' }

      iex> JSON.Parser.Charlist.parse '-12e4and then some'
      {:ok, -1.2e+5, 'and then some' }

      iex> JSON.Parser.Charlist.parse '7842490016E-12-and more'
      {:ok, 7.842490016e-3, '-and more' }

      iex> JSON.Parser.Charlist.parse 'null'
      {:ok, nil, '' }

      iex> JSON.Parser.Charlist.parse 'false'
      {:ok, false, '' }

      iex> JSON.Parser.Charlist.parse 'true'
      {:ok, true, '' }

      iex> JSON.Parser.Charlist.parse '\\\"7.something\\\"'
      {:ok, "7.something", '' }

      iex> JSON.Parser.Charlist.parse '\\\"-88.22suffix\\\" foo bar'
      {:ok, "-88.22suffix", ' foo bar' }

      iex> JSON.Parser.Charlist.parse '[]'
      {:ok, [], '' }

      iex> JSON.Parser.Charlist.parse '["foo", 1, 2, 1.5] lala'
      {:ok, ["foo", 1, 2, 1.5], ' lala' }

      iex> JSON.Parser.Charlist.parse '{"result": "this will be a elixir result"} lalal'
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), ' lalal'}
  """
  def parse([ ?[ | _ ] = charlist) do
    JSON.Parser.Charlist.Array.parse(charlist)
  end

  def parse([ ?{ | _ ] = charlist) do
    JSON.Parser.Charlist.Object.parse(charlist)
  end

  def parse([ ?" | _ ] = charlist) do
    JSON.Parser.Charlist.String.parse(charlist)
  end

  def parse([ ?- , number | _ ] = charlist) when number in ?0..?9 do
    JSON.Parser.Charlist.Number.parse(charlist)
  end

  def parse([ number | _ ] = charlist) when number in ?0..?9 do
    JSON.Parser.Charlist.Number.parse(charlist)
  end


  def parse([ ?n, ?u, ?l, ?l  | rest ]),    do: { :ok, nil,   rest }
  def parse([ ?t, ?r, ?u, ?e  | rest ]),    do: { :ok, true,  rest }
  def parse([ ?f, ?a, ?l, ?s, ?e | rest ]), do: { :ok, false, rest }

  def parse([ ]),  do:  { :error, :unexpected_end_of_buffer }
  def parse(json), do:  { :error, { :unexpected_token, json } }


  @doc """
  parses valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parser.Charlist.trim ''
      ''

      iex> JSON.Parser.Charlist.trim 'xkcd'
      'xkcd'

      iex> JSON.Parser.Charlist.trim '  \\t\\r lalala '
      'lalala '

      iex> JSON.Parser.Charlist.trim ' \\n\\t\\n fooo \\u00dflalalal '
      'fooo \\u00dflalalal '
  """
  def trim(charlist) when is_list(charlist) do
    case charlist do
      #32 = ascii space, clearer than using "? ", I think
      [ 32  | rest ] -> trim rest
      [ ?\t | rest ] -> trim rest
      [ ?\r | rest ] -> trim rest
      [ ?\n | rest ] -> trim rest
      _ -> charlist
    end
  end
end
