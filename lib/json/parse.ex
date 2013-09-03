defmodule JSON.Parse do
  #32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  @doc """
  Consumes valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parse.bitstring_consume_whitespace ""
      ""

      iex> JSON.Parse.bitstring_consume_whitespace "xkcd"
      "xkcd"

      iex> JSON.Parse.bitstring_consume_whitespace "  \\t\\r lalala "
      "lalala "

      iex> JSON.Parse.bitstring_consume_whitespace " \\n\\t\\n fooo \\u00dflalalal "
      "fooo \\u00dflalalal "
  """

  def bitstring_consume_whitespace(<< @acii_space :: utf8, rest :: binary >>), do: bitstring_consume_whitespace(rest)
  def bitstring_consume_whitespace(<< ?\t :: utf8, rest :: binary >>), do: bitstring_consume_whitespace(rest)
  def bitstring_consume_whitespace(<< ?\r :: utf8, rest :: binary >>), do: bitstring_consume_whitespace(rest)
  def bitstring_consume_whitespace(<< ?\n :: utf8, rest :: binary >>), do: bitstring_consume_whitespace(rest)
  def bitstring_consume_whitespace(bitstring) when is_binary(bitstring), do: bitstring

  @doc """
  Consumes valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parse.charlist_consume_whitespace ''
      ''

      iex> JSON.Parse.charlist_consume_whitespace 'xkcd'
      'xkcd'

      iex> JSON.Parse.charlist_consume_whitespace '  \\t\\r lalala '
      'lalala '

      iex> JSON.Parse.charlist_consume_whitespace ' \\n\\t\\n fooo \\u00dflalalal '
      'fooo \\u00dflalalal '
  """
  def charlist_consume_whitespace([ @acii_space | rest ]), do: charlist_consume_whitespace(rest)
  def charlist_consume_whitespace([ ?\t | rest ]), do: charlist_consume_whitespace(rest)
  def charlist_consume_whitespace([ ?\r | rest ]), do: charlist_consume_whitespace(rest)
  def charlist_consume_whitespace([ ?\n | rest ]), do: charlist_consume_whitespace(rest)
  def charlist_consume_whitespace(charlist) when is_list(charlist), do: charlist

  defmodule Value do

    @doc """
    Consumes a valid JSON value, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Value.bitstring_consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Value.bitstring_consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Value.bitstring_consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.Value.bitstring_consume "129245"
        {:ok, 129245, "" }

        iex> JSON.Parse.Value.bitstring_consume "7.something"
        {:ok, 7, ".something" }

        iex> JSON.Parse.Value.bitstring_consume "-88.22suffix"
        {:ok, -88.22, "suffix" }

        iex> JSON.Parse.Value.bitstring_consume "-12e4and then some"
        {:ok, -1.2e+5, "and then some" }

        iex> JSON.Parse.Value.bitstring_consume "7842490016E-12-and more"
        {:ok, 7.842490016e-3, "-and more" }

        iex> JSON.Parse.Value.bitstring_consume "null"
        {:ok, nil, ""}

        iex> JSON.Parse.Value.bitstring_consume "false"
        {:ok, false, "" }

        iex> JSON.Parse.Value.bitstring_consume "true"
        {:ok, true, "" }

        iex> JSON.Parse.Value.bitstring_consume "\\\"7.something\\\""
        {:ok, "7.something", "" }

        iex> JSON.Parse.Value.bitstring_consume "\\\"-88.22suffix\\\" foo bar"
        {:ok, "-88.22suffix", " foo bar" }

        iex> JSON.Parse.Value.bitstring_consume "\\\"star -> \\\\u272d <- star\\\""
        {:ok, "star -> ✭ <- star", "" }

        iex> JSON.Parse.Value.bitstring_consume "[]"
        {:ok, [], "" }

        iex> JSON.Parse.Value.bitstring_consume "[\\\"foo\\\", 1, 2, 1.5] lala"
        {:ok, ["foo", 1, 2, 1.5], " lala" }

        iex> JSON.Parse.Value.bitstring_consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), " lalal"}
    """

    def bitstring_consume(<< ?[, rest :: binary >>), do: JSON.Parse.Array.bitstring_consume( << ?[, rest :: binary >>)
    def bitstring_consume(<< ?{, rest :: binary >>), do: JSON.Parse.Object.bitstring_consume(<< ?{, rest :: binary >>)
    def bitstring_consume(<< ?", rest :: binary >>), do: JSON.Parse.String.bitstring_consume(<< ?", rest :: binary >>)

    def bitstring_consume(<< ?- , number :: utf8, rest :: binary  >>) when number in ?0..?9 do
      JSON.Parse.Number.bitstring_consume(<< ?- , number :: utf8, rest :: binary  >>)
    end

    def bitstring_consume(<< number :: utf8, rest :: binary >>) when number in ?0..?9 do
      JSON.Parse.Number.bitstring_consume(<< number :: utf8, rest :: binary  >>)
    end

    def bitstring_consume(<< ?n, ?u, ?l, ?l, rest :: binary >>), do: { :ok, nil,   rest }
    def bitstring_consume(<< ?t, ?r, ?u, ?e, rest :: binary >>), do: { :ok, true,  rest }
    def bitstring_consume(<< ?f, ?a, ?l, ?s, ?e, rest :: binary >>), do: { :ok, false, rest }

    def bitstring_consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def bitstring_consume(json), do: {:error, { :unexpected_token, json }}

    @doc """
    Consumes a valid JSON value, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Value.charlist_consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Value.charlist_consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Value.charlist_consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.Value.charlist_consume '129245'
        {:ok, 129245, '' }

        iex> JSON.Parse.Value.charlist_consume '7.something'
        {:ok, 7, '.something' }

        iex> JSON.Parse.Value.charlist_consume '-88.22suffix'
        {:ok, -88.22, 'suffix' }

        iex> JSON.Parse.Value.charlist_consume '-12e4and then some'
        {:ok, -1.2e+5, 'and then some' }

        iex> JSON.Parse.Value.charlist_consume '7842490016E-12-and more'
        {:ok, 7.842490016e-3, '-and more' }

        iex> JSON.Parse.Value.charlist_consume 'null'
        {:ok, nil, '' }

        iex> JSON.Parse.Value.charlist_consume 'false'
        {:ok, false, '' }

        iex> JSON.Parse.Value.charlist_consume 'true'
        {:ok, true, '' }

        iex> JSON.Parse.Value.charlist_consume '\\\"7.something\\\"'
        {:ok, "7.something", '' }

        iex> JSON.Parse.Value.charlist_consume '\\\"-88.22suffix\\\" foo bar'
        {:ok, "-88.22suffix", ' foo bar' }

        iex> JSON.Parse.Value.charlist_consume '[]'
        {:ok, [], '' }

        iex> JSON.Parse.Value.charlist_consume '["foo", 1, 2, 1.5] lala'
        {:ok, ["foo", 1, 2, 1.5], ' lala' }

        iex> JSON.Parse.Value.charlist_consume '{"result": "this will be a elixir result"} lalal'
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), ' lalal'}
    """
    def charlist_consume([ ?[ | rest ]), do: JSON.Parse.Array.charlist_consume( [ ?[ | rest ])
    def charlist_consume([ ?{ | rest ]), do: JSON.Parse.Object.charlist_consume([ ?{ | rest ])
    def charlist_consume([ ?" | rest ]), do: JSON.Parse.String.charlist_consume([ ?" | rest ])

    def charlist_consume([ ?- , number | rest]) when number in ?0..?9 do
        JSON.Parse.Number.charlist_consume([ ?- , number | rest])
    end

    def charlist_consume([ number | rest]) when number in ?0..?9 do
        JSON.Parse.Number.charlist_consume([ number | rest])
    end


    def charlist_consume([ ?n, ?u, ?l, ?l  | rest ]),    do: { :ok, nil,   rest }
    def charlist_consume([ ?t, ?r, ?u, ?e  | rest ]),    do: { :ok, true,  rest }
    def charlist_consume([ ?f, ?a, ?l, ?s, ?e | rest ]), do: { :ok, false, rest }

    def charlist_consume([ ]),  do:  {:error, :unexpected_end_of_buffer}
    def charlist_consume(json), do: {:error, { :unexpected_token, json }}
  end

  defmodule Object do
    @doc """
    Consumes a valid JSON object value, returns its elixir HashDict representation

    ## Examples

        iex> JSON.Parse.Object.bitstring_consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Object.bitstring_consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Object.bitstring_consume "[] "
        {:error, {:unexpected_token, "[] "}}

        iex> JSON.Parse.Object.bitstring_consume "[]"
        {:error, {:unexpected_token, "[]"}}

        iex> JSON.Parse.Object.bitstring_consume "[\\\"foo\\\", 1, 2, 1.5] lala"
        {:error, {:unexpected_token, "[\\\"foo\\\", 1, 2, 1.5] lala"}}

        iex> JSON.Parse.Object.bitstring_consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), " lalal"}
    """
    def bitstring_consume(<< ?{, rest :: binary >>) do
      JSON.Parse.bitstring_consume_whitespace(rest) |> bitstring_consume_object_contents
    end

    def bitstring_consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def bitstring_consume(json),  do: {:error, { :unexpected_token, json }}

    @doc """
    Consumes a valid JSON object value, returns its elixir HashDict representation

    ## Examples

        iex> JSON.Parse.Object.charlist_consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Object.charlist_consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Object.charlist_consume '[] '
        {:error, {:unexpected_token, '[] '}}

        iex> JSON.Parse.Object.charlist_consume '[]'
        {:error, {:unexpected_token, '[]'}}

        iex> JSON.Parse.Object.charlist_consume '{"result": "this will be a elixir result"} lalal'
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), ' lalal'}
    """
    def charlist_consume([ ?{ | rest ]) do
      JSON.Parse.charlist_consume_whitespace(rest) |> charlist_consume_object_contents
    end

    def charlist_consume([ ]),  do:  {:error, :unexpected_end_of_buffer}
    def charlist_consume(json), do: {:error, { :unexpected_token, json }}

    # Object Parsing
    defp bitstring_consume_object_key(json) do
      case JSON.Parse.String.bitstring_consume(json) do
        {:error, error_info} -> {:error, error_info}
        {:ok, key, after_key } ->
          case JSON.Parse.bitstring_consume_whitespace(after_key) do
            << ?:,  after_colon :: binary >> -> {:ok, key, JSON.Parse.bitstring_consume_whitespace(after_colon)}
            << >> -> { :error, :unexpected_end_of_buffer}
            _     -> { :error, {:unexpected_token, JSON.Parse.bitstring_consume_whitespace(after_key) }}
          end
      end
    end

    defp bitstring_consume_object_value(acc, key, after_key) do
      case JSON.Parse.Value.bitstring_consume(after_key) do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value} ->
          acc  = HashDict.put(acc, key, value)
          after_value = JSON.Parse.bitstring_consume_whitespace(after_value)
          case after_value do
            << ?,, after_comma :: binary >> ->  bitstring_consume_object_contents(acc, JSON.Parse.bitstring_consume_whitespace(after_comma))
            _ -> bitstring_consume_object_contents(acc, after_value)
          end
      end
    end

    defp bitstring_consume_object_contents(json), do: bitstring_consume_object_contents(HashDict.new, json)

    defp bitstring_consume_object_contents(acc, << ?", rest :: binary >>) do
      case bitstring_consume_object_key(<< ?" , rest :: binary >>) do
        {:error, error_info}  -> {:error, error_info}
        {:ok, key, after_key} -> bitstring_consume_object_value(acc, key, after_key)
      end
    end

    defp bitstring_consume_object_contents(acc, << ?}, rest :: binary >>), do: { :ok, acc, rest }

    defp bitstring_consume_object_contents(_, << >>),  do: {:error, :unexpected_end_of_buffer }
    defp bitstring_consume_object_contents(_, json), do: {:error, { :unexpected_token, json } }

    #charlists
    defp charlist_consume_object_key(json) when is_list(json) or is_binary(json) do
      case JSON.Parse.String.charlist_consume(json) do
        {:error, error_info} -> {:error, error_info}
        {:ok, key, after_key } ->
          case JSON.Parse.charlist_consume_whitespace(after_key) do
            [ ?: | after_colon ] -> {:ok, key, JSON.Parse.charlist_consume_whitespace(after_colon)}
            []    -> { :error, :unexpected_end_of_buffer}
            _     -> { :error, {:unexpected_token, JSON.Parse.charlist_consume_whitespace(after_key) }}
          end
      end
    end

    defp charlist_consume_object_value(acc, key, after_key) do
      case JSON.Parse.Value.charlist_consume(after_key) do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value} ->
          acc  = HashDict.put(acc, key, value)
          after_value = JSON.Parse.charlist_consume_whitespace(after_value)
          case after_value do
            [ ?, | after_comma ] -> charlist_consume_object_contents(acc, JSON.Parse.charlist_consume_whitespace(after_comma))
            _ -> charlist_consume_object_contents(acc, after_value)
          end
      end
    end

    defp charlist_consume_object_contents(json), do: charlist_consume_object_contents(HashDict.new, json)

    defp charlist_consume_object_contents(acc, [ ?" | rest]) do
      case charlist_consume_object_key([ ?" | rest]) do
        {:error, error_info}  -> {:error, error_info}
        {:ok, key, after_key} -> charlist_consume_object_value(acc, key, after_key)
      end
    end

    defp charlist_consume_object_contents(acc, [ ?} | rest ]), do: { :ok, acc, rest }

    defp charlist_consume_object_contents(_, []), do: {:error, :unexpected_end_of_buffer }
    defp charlist_consume_object_contents(_, json), do: {:error, { :unexpected_token, json } }
  end

  defmodule Array do
    @doc """
    Consumes a valid JSON array value, returns its elixir list representation

    ## Examples

        iex> JSON.Parse.Array.bitstring_consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.bitstring_consume "[1, 2 "
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.bitstring_consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Array.bitstring_consume "[] lala"
        {:ok, [], " lala" }

        iex> JSON.Parse.Array.bitstring_consume "[]"
        {:ok, [], "" }

        iex> JSON.Parse.Array.bitstring_consume "[\\\"foo\\\", 1, 2, 1.5] lala"
        {:ok, ["foo", 1, 2, 1.5], " lala" }
    """
    def bitstring_consume(<< ?[, rest :: binary >>) do
      JSON.Parse.bitstring_consume_whitespace(rest) |> bitstring_consume_array_contents
    end

    def bitstring_consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def bitstring_consume(json),  do: {:error, { :unexpected_token, json }}


    defp bitstring_consume_array_contents(json) when is_binary(json), do: bitstring_consume_array_contents([], json)

    defp bitstring_consume_array_contents(acc, << ?], rest :: binary >>), do: {:ok, Enum.reverse(acc), rest }
    defp bitstring_consume_array_contents(_, << >> ), do: { :error,  :unexpected_end_of_buffer }

    defp bitstring_consume_array_contents(acc, json) do
      case JSON.Parse.bitstring_consume_whitespace(json) |> JSON.Parse.Value.bitstring_consume do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value } ->
          after_value = JSON.Parse.bitstring_consume_whitespace(after_value)
          case after_value  do
            << ?, , after_comma :: binary >> ->
              bitstring_consume_array_contents([ value | acc ], JSON.Parse.bitstring_consume_whitespace(after_comma))
            _ ->
              bitstring_consume_array_contents([ value | acc ], after_value)
          end
      end
    end


    @doc """
    Consumes a valid JSON array value, returns its elixir list representation

    ## Examples

        iex> JSON.Parse.Array.charlist_consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.charlist_consume '[1, 2 '
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.charlist_consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Array.charlist_consume '[] lala'
        {:ok, [], ' lala' }

        iex> JSON.Parse.Array.charlist_consume '[]'
        {:ok, [], '' }

        iex> JSON.Parse.Array.charlist_consume '["foo", 1, 2, 1.5] lala'
        {:ok, ["foo", 1, 2, 1.5], ' lala' }
    """
    def charlist_consume([ ?[ | rest ]) do
      JSON.Parse.charlist_consume_whitespace(rest) |> charlist_consume_array_contents
    end
    def charlist_consume([ ]),  do:  {:error, :unexpected_end_of_buffer}
    def charlist_consume(json), do: {:error, { :unexpected_token, json }}


    # Array Parsing
    defp charlist_consume_array_contents(json) when is_list(json), do: charlist_consume_array_contents([], json)

    defp charlist_consume_array_contents(acc, [ ?] | rest ]), do: {:ok, Enum.reverse(acc), rest }
    defp charlist_consume_array_contents(_, [] ), do: { :error, :unexpected_end_of_buffer }

    defp charlist_consume_array_contents(acc, json) do
      case JSON.Parse.charlist_consume_whitespace(json) |> JSON.Parse.Value.charlist_consume do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value } ->
          after_value = JSON.Parse.charlist_consume_whitespace(after_value)
          case after_value  do
            [ ?, | after_comma ] ->
              charlist_consume_array_contents([ value | acc ], JSON.Parse.charlist_consume_whitespace(after_comma))
            _ ->
              charlist_consume_array_contents([ value | acc ], after_value)
          end
      end
    end
  end


  defmodule String do
    @doc """
    Consumes a valid JSON string, returns its elixir representation

    ## Examples

        iex> JSON.Parse.String.bitstring_consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.String.bitstring_consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.String.bitstring_consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.String.bitstring_consume "129245"
        {:error, {:unexpected_token, "129245"} }

        iex> JSON.Parse.String.bitstring_consume "\\\"7.something\\\""
        {:ok, "7.something", "" }

        iex> JSON.Parse.String.bitstring_consume "\\\"-88.22suffix\\\" foo bar"
        {:ok, "-88.22suffix", " foo bar" }

        iex> JSON.Parse.String.bitstring_consume "\\\"star -> \\\\u272d <- star\\\""
        {:ok, "star -> ✭ <- star", "" }

        iex> JSON.Parse.String.bitstring_consume "\\\"Rafaëlla\\\" foo bar"
        {:ok, "Rafaëlla", " foo bar" }

        iex> JSON.Parse.String.bitstring_consume "\\\"Éloise woot\\\" Éloise"
        {:ok, "Éloise woot", " Éloise" }
    """
    def bitstring_consume(<< ?" :: utf8 , rest :: binary >>), do: bitstring_consume_string_contents(rest, [])
    def bitstring_consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def bitstring_consume(json), do: {:error, { :unexpected_token, json }}


    #stop conditions
    defp bitstring_consume_string_contents(<< >>, _), do: {:error, :unexpected_end_of_buffer}
    defp bitstring_consume_string_contents(<< ?" :: utf8, rest :: binary >>, acc) do
      case Elixir.String.from_char_list(acc) do
        {:ok, encoded_string } -> { :ok, encoded_string, rest }
        _ -> {:error, { :unexpected_token, rest }}
      end
    end

    #parsing
    defp bitstring_consume_string_contents(<< ?\\, ?f,  rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?\f ])
    defp bitstring_consume_string_contents(<< ?\\, ?n,  rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?\n ])
    defp bitstring_consume_string_contents(<< ?\\, ?r,  rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?\r ])
    defp bitstring_consume_string_contents(<< ?\\, ?t,  rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?\t ])
    defp bitstring_consume_string_contents(<< ?\\, ?",  rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?"  ])
    defp bitstring_consume_string_contents(<< ?\\, ?\\, rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?\\ ])
    defp bitstring_consume_string_contents(<< ?\\, ?/,  rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, ?/  ])

    defp bitstring_consume_string_contents(<< ?\\, ?u , rest :: binary >>, acc) do
      case JSON.Parse.UnicodeEscape.bitstring_consume(<< ?\\, ?u , rest :: binary >>) do
        { :error, error_info } -> { :error, error_info }
        { :ok, value, rest } -> bitstring_consume_string_contents(rest, [ acc, value ])
      end
    end

    defp bitstring_consume_string_contents(<< char :: utf8, rest :: binary >>, acc), do: bitstring_consume_string_contents(rest, [ acc, char ])

    @doc """
    Consumes a valid JSON string, returns its elixir representation

    ## Examples

        iex> JSON.Parse.String.charlist_consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.String.charlist_consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.String.charlist_consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.String.charlist_consume '129245'
        {:error, {:unexpected_token, '129245'} }

        iex> JSON.Parse.String.charlist_consume '\\\"7.something\\\"'
        {:ok, "7.something", '' }

        iex> JSON.Parse.String.charlist_consume '\\\"-88.22suffix\\\" foo bar'
        {:ok, "-88.22suffix", ' foo bar' }

    """
    def charlist_consume([ ?" | rest ]), do: charlist_consume_string_contents(rest, [])
    def charlist_consume([ ]),  do:  {:error, :unexpected_end_of_buffer}
    def charlist_consume(json), do: {:error, { :unexpected_token, json }}


    #stop conditions
    defp charlist_consume_string_contents([], _), do: {:error, :unexpected_end_of_buffer}
    defp charlist_consume_string_contents([ ?" | rest ], acc), do: { :ok, iolist_to_binary(acc), rest }

    #parsing
    defp charlist_consume_string_contents([ ?\\, ?f  | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?\f ])
    defp charlist_consume_string_contents([ ?\\, ?n  | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?\n ])
    defp charlist_consume_string_contents([ ?\\, ?r  | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?\r ])
    defp charlist_consume_string_contents([ ?\\, ?t  | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?\t ])
    defp charlist_consume_string_contents([ ?\\, ?"  | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?"  ])
    defp charlist_consume_string_contents([ ?\\, ?\\ | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?\\ ])
    defp charlist_consume_string_contents([ ?\\, ?/  | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, ?/  ])

    defp charlist_consume_string_contents([ ?\\, ?u  | rest ], acc) do
      case JSON.Parse.UnicodeEscape.charlist_consume([ ?\\, ?u  | rest ]) do
        { :error, error_info } -> { :error, error_info }
        { :ok, value, rest } -> charlist_consume_string_contents(rest, [ acc, value ])
      end
    end

    defp charlist_consume_string_contents([ char | rest ], acc), do: charlist_consume_string_contents(rest, [ acc, char ])

  end

  defmodule UnicodeEscape do
    @doc """
    Consumes a JSON Unicode Escaped character, returns its UTF8 representation

    ## Examples

        iex> JSON.Parse.UnicodeEscape.bitstring_consume ""
        { :error, :unexpected_end_of_buffer }

        iex> JSON.Parse.UnicodeEscape.bitstring_consume "foo"
        { :error, { :unexpected_token, "foo" } }

        iex> JSON.Parse.UnicodeEscape.bitstring_consume "\\\\u00df"
        { :ok, "ß", "" }

        iex> JSON.Parse.UnicodeEscape.bitstring_consume "\\\\u00dflalalal"
        { :ok, "ß", "lalalal" }
    """
    def bitstring_consume(<< ?\\, ?u , rest :: binary >>) do
      case bitstring_consume_unicode_escape(rest, 0, 0) do
        { :ok, tentative_codepoint, after_tentative_codepoint} ->
          if Elixir.String.valid_codepoint? tentative_codepoint do
            { :ok, tentative_codepoint, after_tentative_codepoint}
          else
            {:error, { :unexpected_token, << ?\\, ?u, rest >> } }
          end
        { :error, error_info } -> { :error, error_info }
      end
    end

    def bitstring_consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def bitstring_consume(json) when is_binary(json), do: {:error, { :unexpected_token, json }}


    #The only OK stop conditions (consumed 4 expected chars successfully)
    defp bitstring_consume_unicode_escape(json, acc, chars_consumed) when 4 === chars_consumed do
      { :ok, << acc :: utf8 >>, json }
    end

    defp bitstring_consume_unicode_escape(<< >>, _, _), do: {:error, :unexpected_end_of_buffer}

    defp bitstring_consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?0..?9 do
      bitstring_consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1)
    end

    defp bitstring_consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?a..?f do
      bitstring_consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1)
    end

    defp bitstring_consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?A..?F do
      bitstring_consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1)
    end

    defp bitstring_consume_unicode_escape(json, _, _), do: {:error, {:unexpected_token, json}}


    @doc """
    Consumes a JSON Unicode Escaped character, returns its UTF8 representation

    ## Examples

        iex> JSON.Parse.UnicodeEscape.charlist_consume ''
        { :error, :unexpected_end_of_buffer }

        iex> JSON.Parse.UnicodeEscape.charlist_consume 'xkcd'
        { :error, {:unexpected_token, 'xkcd'} }

        iex> JSON.Parse.UnicodeEscape.charlist_consume '\\\\u00df'
        { :ok, "ß", '' }

        iex> JSON.Parse.UnicodeEscape.charlist_consume '\\\\u00dflalalal'
        { :ok, "ß", 'lalalal' }

    """
    def charlist_consume([?\\, ?u | rest]) do
      case charlist_consume_unicode_escape(rest, 0, 0) do
        { :ok, tentative_codepoint, after_tentative_codepoint} ->
          if Elixir.String.valid_codepoint? tentative_codepoint do
            { :ok, tentative_codepoint, after_tentative_codepoint}
          else
            {:error, { :unexpected_token, [?\\, ?u | rest] } }
          end
        { :error, error_info } -> { :error, error_info }
      end
    end

    def charlist_consume([ ]),   do:  {:error, :unexpected_end_of_buffer}
    def charlist_consume(json) when is_list(json), do: {:error, { :unexpected_token, json }}

    defp charlist_consume_unicode_escape(json, acc, chars_consumed) when 4 === chars_consumed do
      { :ok, << acc :: utf8 >>, json }
    end

    defp charlist_consume_unicode_escape([], _, _), do: {:error, :unexpected_end_of_buffer}

    defp charlist_consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?0..?9 do
      charlist_consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1)
    end

    defp charlist_consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?a..?f do
      charlist_consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1)
    end

    defp charlist_consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?A..?F do
      charlist_consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1)
    end

    defp charlist_consume_unicode_escape(json, _, _), do: {:error, {:unexpected_token, json}}
  end

  defmodule Number do
    @doc """
    Consumes a valid JSON numerical value, returns its elixir numerical representation

    ## Examples

        iex> JSON.Parse.Number.bitstring_consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Number.bitstring_consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Number.bitstring_consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.Number.bitstring_consume "129245"
        {:ok, 129245, "" }

        iex> JSON.Parse.Number.bitstring_consume "7.something"
        {:ok, 7, ".something" }

        iex> JSON.Parse.Number.bitstring_consume "7.4566something"
        {:ok, 7.4566, "something" }

        iex> JSON.Parse.Number.bitstring_consume "-88.22suffix"
        {:ok, -88.22, "suffix" }

        iex> JSON.Parse.Number.bitstring_consume "-12e4and then some"
        {:ok, -1.2e+5, "and then some" }

        iex> JSON.Parse.Number.bitstring_consume "7842490016E-12-and more"
        {:ok, 7.842490016e-3, "-and more" }
    """
    def bitstring_consume(<< ?- , number :: utf8 ,  rest :: binary >>) when number in ?0..?9 do
      bitstring_consume(<< number :: utf8, rest :: binary>>) |> negate
    end

    def bitstring_consume(<< number :: utf8 ,  rest :: binary >>) when number in ?0..?9 do
      bitstring_to_integer(<< number :: utf8, rest :: binary >>) |> bitstring_add_fractional |> bitstring_apply_exponent
    end

    def bitstring_consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def bitstring_consume(json), do: {:error, { :unexpected_token, json }}

    defp bitstring_add_fractional({:ok, acc, << ?., c :: utf8, rest :: binary >> }) when c in ?0..?9 do
      { fractional, rest } = bitstring_consume_fractional(<< c :: utf8,  rest :: binary >>, 0, 10.0)
      {:ok, acc + fractional, rest }
    end

    defp bitstring_add_fractional({:ok, acc, json }), do: {:ok, acc, json }

    defp bitstring_consume_fractional(<< number :: utf8, rest :: binary >>, acc, power) when number in ?0..?9 do
      bitstring_consume_fractional(rest, acc + (number - ?0) / power, power * 10)
    end

    defp bitstring_consume_fractional(json, acc , _) when is_binary(json), do: { acc, json }

    defp bitstring_apply_exponent({:ok, acc, << exponent :: utf8, rest :: binary >> }) when exponent in [?e, ?E] do
      case bitstring_to_integer(rest) do
        { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
        { :error, error_info } -> { :error, error_info }
      end
    end

    # ensures the following behavior - JSON.Parse.Number.consume "7842490016E-12-and more" - {:ok, 7.842490016e-3, '-and more' }
    defp bitstring_apply_exponent({:ok, acc, json }), do: {:ok, acc, json }

    # mini-wrapper around Elixir.String.to_integer
    defp bitstring_to_integer(<< >>), do: {:error,  :unexpected_end_of_buffer}

    defp bitstring_to_integer(bitstring) do
      case Elixir.String.to_integer(bitstring) do
        :error -> {:error, {:unexpected_token, bitstring} }
        { result, rest } -> {:ok, result, rest}
      end
    end


    @doc """
    Consumes a valid JSON numerical value, returns its elixir numerical representation

    ## Examples

        iex> JSON.Parse.Number.charlist_consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Number.charlist_consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Number.charlist_consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.Number.charlist_consume '129245'
        {:ok, 129245, '' }

        iex> JSON.Parse.Number.charlist_consume '7.something'
        {:ok, 7, '.something' }

        iex> JSON.Parse.Number.charlist_consume '7.4566something'
        {:ok, 7.4566, 'something' }

        iex> JSON.Parse.Number.charlist_consume '-88.22suffix'
        {:ok, -88.22, 'suffix' }

        iex> JSON.Parse.Number.charlist_consume '-12e4and then some'
        {:ok, -1.2e+5, 'and then some' }

        iex> JSON.Parse.Number.charlist_consume '7842490016E-12-and more'
        {:ok, 7.842490016e-3, '-and more' }
    """
    def charlist_consume([ ?- , number | rest]) when number in ?0..?9 do
      charlist_consume([number | rest]) |> negate
    end

    def charlist_consume([ number | rest]) when number in ?0..?9 do
      iolist_to_integer([ number | rest]) |> charlist_add_fractional |> charlist_apply_exponent
    end

    def charlist_consume([ ]), do:  {:error, :unexpected_end_of_buffer}
    def charlist_consume(json) when is_list(json), do: {:error, { :unexpected_token, json }}

    #fractional
    defp charlist_add_fractional({:error, error_info}), do: {:error, error_info}

    defp charlist_add_fractional({:ok, acc, [ ?., c | rest ] }) when c in ?0..?9 do
      { fractional, rest } = charlist_consume_fractional([ c | rest ], 0, 10.0)
      {:ok, acc + fractional, rest }
    end

    defp charlist_add_fractional({:ok, acc, json }) when is_list(json), do: {:ok, acc, json }

    defp charlist_consume_fractional([ number | rest ], acc, power) when number in ?0..?9 do
      charlist_consume_fractional(rest, acc + (number - ?0) / power, power * 10)
    end

    defp charlist_consume_fractional(json, acc , _) when is_list(json), do: { acc, json }


    #exponent
    defp charlist_apply_exponent({:error, error_info}), do: { :error, error_info }

    defp charlist_apply_exponent({:ok, acc, [ exponent | rest ] }) when exponent in [?e, ?E] do
      case iolist_to_integer(rest) do
        { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
        { :error, error_info } -> { :error, error_info }
      end
    end

    defp charlist_apply_exponent({:ok, acc, json }) when is_list(json), do: {:ok, acc, json }

    # mini-wrapper around :string.to_integer
    defp iolist_to_integer([]), do: {:error, :unexpected_end_of_buffer}

    defp iolist_to_integer(iolist) when is_list(iolist) do
      case :string.to_integer(iolist) do
        { :error, _ } -> {:error, {:unexpected_token, iolist} }
        { result, rest } -> {:ok, result, rest}
      end
    end

    defp negate({:error, error_info}), do: {:error, error_info}
    defp negate({:ok, number, json }), do: {:ok, -1 * number, json }
  end
end
