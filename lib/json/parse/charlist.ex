defmodule JSON.Parse.Charlist do
  @doc """
  Consumes a valid JSON value, returns its elixir representation

  ## Examples

      iex> JSON.Parse.Charlist.consume ''
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parse.Charlist.consume 'face0ff'
      {:error, {:unexpected_token, 'face0ff'} }

      iex> JSON.Parse.Charlist.consume '-hello'
      {:error, {:unexpected_token, '-hello'} }

      iex> JSON.Parse.Charlist.consume '129245'
      {:ok, 129245, '' }

      iex> JSON.Parse.Charlist.consume '7.something'
      {:ok, 7, '.something' }

      iex> JSON.Parse.Charlist.consume '-88.22suffix'
      {:ok, -88.22, 'suffix' }

      iex> JSON.Parse.Charlist.consume '-12e4and then some'
      {:ok, -1.2e+5, 'and then some' }

      iex> JSON.Parse.Charlist.consume '7842490016E-12-and more'
      {:ok, 7.842490016e-3, '-and more' }

      iex> JSON.Parse.Charlist.consume 'null'
      {:ok, nil, '' }

      iex> JSON.Parse.Charlist.consume 'false'
      {:ok, false, '' }

      iex> JSON.Parse.Charlist.consume 'true'
      {:ok, true, '' }

      iex> JSON.Parse.Charlist.consume '\\\"7.something\\\"'
      {:ok, "7.something", '' }

      iex> JSON.Parse.Charlist.consume '\\\"-88.22suffix\\\" foo bar'
      {:ok, "-88.22suffix", ' foo bar' }

      iex> JSON.Parse.Charlist.consume '[]'
      {:ok, [], '' }

      iex> JSON.Parse.Charlist.consume '["foo", 1, 2, 1.5] lala'
      {:ok, ["foo", 1, 2, 1.5], ' lala' }

      iex> JSON.Parse.Charlist.consume '{"result": "this will be a elixir result"} lalal'
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), ' lalal'}
  """
  def consume([ ?[ | _ ] = charlist) do
    JSON.Parse.Charlist.Array.consume(charlist)
  end

  def consume([ ?{ | _ ] = charlist) do
    JSON.Parse.Charlist.Object.consume(charlist)
  end

  def consume([ ?" | _ ] = charlist) do
    JSON.Parse.Charlist.String.consume(charlist)
  end

  def consume([ ?- , number | _ ] = charlist) when number in ?0..?9 do
    JSON.Parse.Charlist.Number.consume(charlist)
  end

  def consume([ number | _ ] = charlist) when number in ?0..?9 do
    JSON.Parse.Charlist.Number.consume(charlist)
  end


  def consume([ ?n, ?u, ?l, ?l  | rest ]),    do: { :ok, nil,   rest }
  def consume([ ?t, ?r, ?u, ?e  | rest ]),    do: { :ok, true,  rest }
  def consume([ ?f, ?a, ?l, ?s, ?e | rest ]), do: { :ok, false, rest }

  def consume([ ]),  do:  { :error, :unexpected_end_of_buffer }
  def consume(json), do:  { :error, { :unexpected_token, json } }


  @doc """
  Consumes valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parse.Charlist.trim ''
      ''

      iex> JSON.Parse.Charlist.trim 'xkcd'
      'xkcd'

      iex> JSON.Parse.Charlist.trim '  \\t\\r lalala '
      'lalala '

      iex> JSON.Parse.Charlist.trim ' \\n\\t\\n fooo \\u00dflalalal '
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
