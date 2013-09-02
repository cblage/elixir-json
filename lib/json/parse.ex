defmodule JSON.Parse do
  #32 = ascii space, cleaner than using "? ", I think
  @acii_space 32

  @doc """
  Consumes valid JSON whitespace if it exists, returns the rest of the buffer

  ## Examples

      iex> JSON.Parse.consume_whitespace ''
      ''

      iex> JSON.Parse.consume_whitespace ""
      ""

      iex> JSON.Parse.consume_whitespace 'xkcd'
      'xkcd'

      iex> JSON.Parse.consume_whitespace "xkcd"
      "xkcd"

      iex> JSON.Parse.consume_whitespace '  \\t\\r lalala '
      'lalala '

      iex> JSON.Parse.consume_whitespace "  \\t\\r lalala "
      "lalala "

      iex> JSON.Parse.consume_whitespace ' \\n\\t\\n fooo \\u00dflalalal '
      'fooo \\u00dflalalal '

      iex> JSON.Parse.consume_whitespace " \\n\\t\\n fooo \\u00dflalalal "
      "fooo \\u00dflalalal "
  """
  def consume_whitespace(<< @acii_space :: utf8, rest :: binary >>), do: consume_whitespace(rest)
  def consume_whitespace(<< ?\t :: utf8, rest :: binary >>), do: consume_whitespace(rest)
  def consume_whitespace(<< ?\r :: utf8, rest :: binary >>), do: consume_whitespace(rest)
  def consume_whitespace(<< ?\n :: utf8, rest :: binary >>), do: consume_whitespace(rest)

  def consume_whitespace([ @acii_space | rest ]), do: consume_whitespace(rest)
  def consume_whitespace([ ?\t | rest ]), do: consume_whitespace(rest)
  def consume_whitespace([ ?\r | rest ]), do: consume_whitespace(rest)
  def consume_whitespace([ ?\n | rest ]), do: consume_whitespace(rest)

  def consume_whitespace(iolist) when is_list(iolist) or is_binary(iolist), do: iolist

  defmodule Value do
    @doc """
    Consumes a valid JSON value, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Value.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Value.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Value.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Value.consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.Value.consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.Value.consume '129245'
        {:ok, 129245, '' }

        iex> JSON.Parse.Value.consume "129245"
        {:ok, 129245, "" }

        iex> JSON.Parse.Value.consume '7.something'
        {:ok, 7, '.something' }

        iex> JSON.Parse.Value.consume "7.something"
        {:ok, 7, ".something" }

        iex> JSON.Parse.Value.consume '-88.22suffix'
        {:ok, -88.22, 'suffix' }

        iex> JSON.Parse.Value.consume "-88.22suffix"
        {:ok, -88.22, "suffix" }

        iex> JSON.Parse.Value.consume '-12e4and then some'
        {:ok, -1.2e+5, 'and then some' }

        iex> JSON.Parse.Value.consume "-12e4and then some"
        {:ok, -1.2e+5, "and then some" }

        iex> JSON.Parse.Value.consume '7842490016E-12-and more'
        {:ok, 7.842490016e-3, '-and more' }

        iex> JSON.Parse.Value.consume "7842490016E-12-and more"
        {:ok, 7.842490016e-3, "-and more" }

        iex> JSON.Parse.Value.consume 'null'
        {:ok, nil, '' }

        iex> JSON.Parse.Value.consume "null"
        {:ok, nil, ""}

        iex> JSON.Parse.Value.consume 'false'
        {:ok, false, '' }

        iex> JSON.Parse.Value.consume "false"
        {:ok, false, "" }

        iex> JSON.Parse.Value.consume 'true'
        {:ok, true, '' }

        iex> JSON.Parse.Value.consume "true"
        {:ok, true, "" }

        iex> JSON.Parse.Value.consume '\\\"7.something\\\"'
        {:ok, "7.something", '' }

        iex> JSON.Parse.Value.consume "\\\"7.something\\\""
        {:ok, "7.something", "" }

        iex> JSON.Parse.Value.consume "\\\"-88.22suffix\\\" foo bar"
        {:ok, "-88.22suffix", " foo bar" }

        iex> JSON.Parse.Value.consume '\\\"-88.22suffix\\\" foo bar'
        {:ok, "-88.22suffix", ' foo bar' }

        iex> JSON.Parse.Value.consume "\\\"star -> \\\\u272d <- star\\\""
        {:ok, "star -> ✭ <- star", "" }

        iex> JSON.Parse.Value.consume '[]'
        {:ok, [], '' }

        iex> JSON.Parse.Value.consume "[]"
        {:ok, [], "" }

        iex> JSON.Parse.Value.consume '["foo", 1, 2, 1.5] lala'
        {:ok, ["foo", 1, 2, 1.5], ' lala' }

        iex> JSON.Parse.Value.consume "[\\\"foo\\\", 1, 2, 1.5] lala"
        {:ok, ["foo", 1, 2, 1.5], " lala" }

        iex> JSON.Parse.Value.consume '{"result": "this will be a elixir result"} lalal'
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), ' lalal'}

        iex> JSON.Parse.Value.consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), " lalal"}

    """
    def consume([ ?[ | rest ]), do: JSON.Parse.Array.consume( [ ?[ | rest ])
    def consume([ ?{ | rest ]), do: JSON.Parse.Object.consume([ ?{ | rest ])
    def consume([ ?" | rest ]), do: JSON.Parse.String.consume([ ?" | rest ])

    def consume([ ?- , number | rest]) when number in ?0..?9, do: JSON.Parse.Number.consume([ ?- , number | rest])
    def consume([ number | rest]) when number in ?0..?9, do: JSON.Parse.Number.consume([ number | rest])
    def consume(<< ?[, rest :: binary >>), do: JSON.Parse.Array.consume( << ?[, rest :: binary >>)
    def consume(<< ?{, rest :: binary >>), do: JSON.Parse.Object.consume(<< ?{, rest :: binary >>)
    def consume(<< ?", rest :: binary >>), do: JSON.Parse.String.consume(<< ?", rest :: binary >>)

    def consume(<< ?- , number :: utf8, rest :: binary  >>) when number in ?0..?9 do
      JSON.Parse.Number.consume(<< ?- , number :: utf8, rest :: binary  >>)
    end

    def consume(<< number :: utf8, rest :: binary >>) when number in ?0..?9 do
      JSON.Parse.Number.consume(<< number :: utf8, rest :: binary  >>)
    end

    def consume([ ?n, ?u, ?l, ?l  | rest ]),    do: { :ok, nil,   rest }
    def consume([ ?t, ?r, ?u, ?e  | rest ]),    do: { :ok, true,  rest }
    def consume([ ?f, ?a, ?l, ?s, ?e | rest ]), do: { :ok, false, rest }

    def consume("null"  <> rest), do: { :ok, nil,   rest }
    def consume("true"  <> rest), do: { :ok, true,  rest }
    def consume("false" <> rest), do: { :ok, false, rest }

    def consume([ ]), do:  {:error, :unexpected_end_of_buffer}
    def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def consume(json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json }}
  end

  defmodule Object do
    @doc """
    Consumes a valid JSON object value, returns its elixir HashDict representation

    ## Examples

        iex> JSON.Parse.Object.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Object.consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Object.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Object.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Object.consume '[] '
        {:error, {:unexpected_token, '[] '}}

        iex> JSON.Parse.Object.consume "[] "
        {:error, {:unexpected_token, "[] "}}

        iex> JSON.Parse.Object.consume "[]"
        {:error, {:unexpected_token, "[]"}}

        iex> JSON.Parse.Object.consume "[\\\"foo\\\", 1, 2, 1.5] lala"
        {:error, {:unexpected_token, "[\\\"foo\\\", 1, 2, 1.5] lala"}}

        iex> JSON.Parse.Object.consume '{"result": "this will be a elixir result"} lalal'
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), ' lalal'}

        iex> JSON.Parse.Object.consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), " lalal"}
    """
    def consume([ ?{ | rest ]), do: JSON.Parse.consume_whitespace(rest) |> consume_object_contents

    def consume(<< ?{, rest :: binary >>), do: JSON.Parse.consume_whitespace(rest) |> consume_object_contents

    def consume([ ]), do:  {:error, :unexpected_end_of_buffer}
    def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}

    def consume(json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json }}

    # Object Parsing
    defp consume_object_key(json) when is_list(json) or is_binary(json) do
      case JSON.Parse.String.consume(json) do
        {:error, error_info} -> {:error, error_info}
        {:ok, key, after_key } ->
          case JSON.Parse.consume_whitespace(after_key) do
            << ?:,  after_colon :: binary >> -> {:ok, key, JSON.Parse.consume_whitespace(after_colon)}
            [ ?: | after_colon ] -> {:ok, key, JSON.Parse.consume_whitespace(after_colon)}
            << >> -> { :error, :unexpected_end_of_buffer}
            []    -> { :error, :unexpected_end_of_buffer}
            _     -> { :error, {:unexpected_token, JSON.Parse.consume_whitespace(after_key) }}
          end
      end
    end

    defp consume_object_value(acc, key, after_key) do
      case JSON.Parse.Value.consume(after_key) do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value} ->
          acc  = HashDict.put(acc, key, value)
          after_value = JSON.Parse.consume_whitespace(after_value)
          case after_value do
            << ?,, after_comma :: binary >> ->  consume_object_contents(acc, JSON.Parse.consume_whitespace(after_comma))
            [ ?, | after_comma ] ->  consume_object_contents(acc, JSON.Parse.consume_whitespace(after_comma))
            _ -> consume_object_contents(acc, after_value)
          end
      end
    end

    defp consume_object_contents(json) when is_list(json) or is_binary(json), do: consume_object_contents(HashDict.new, json)

    defp consume_object_contents(acc, [ ?" | rest]) do
      case consume_object_key([ ?" | rest]) do
        {:error, error_info}  -> {:error, error_info}
        {:ok, key, after_key} -> consume_object_value(acc, key, after_key)
      end
    end

    defp consume_object_contents(acc, << ?", rest :: binary >>) do
      case consume_object_key(<< ?" , rest :: binary >>) do
        {:error, error_info}  -> {:error, error_info}
        {:ok, key, after_key} -> consume_object_value(acc, key, after_key)
      end
    end

    defp consume_object_contents(acc, [ ?} | rest ]), do: { :ok, acc, rest }
    defp consume_object_contents(acc, << ?}, rest :: binary >>), do: { :ok, acc, rest }

    defp consume_object_contents(_, << >>),  do: {:error, :unexpected_end_of_buffer }
    defp consume_object_contents(_, []),     do: {:error, :unexpected_end_of_buffer }

    defp consume_object_contents(_, json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json } }
  end

  defmodule Array do
    @doc """
    Consumes a valid JSON array value, returns its elixir list representation

    ## Examples

        iex> JSON.Parse.Array.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.consume '[1, 2 '
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.consume "[1, 2 "
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Array.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Array.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Array.consume '[] lala'
        {:ok, [], ' lala' }

        iex> JSON.Parse.Array.consume "[] lala"
        {:ok, [], " lala" }

        iex> JSON.Parse.Array.consume '[]'
        {:ok, [], '' }

        iex> JSON.Parse.Array.consume "[]"
        {:ok, [], "" }

        iex> JSON.Parse.Array.consume '["foo", 1, 2, 1.5] lala'
        {:ok, ["foo", 1, 2, 1.5], ' lala' }

        iex> JSON.Parse.Array.consume "[\\\"foo\\\", 1, 2, 1.5] lala"
        {:ok, ["foo", 1, 2, 1.5], " lala" }
    """
    def consume([ ?[ | rest ]), do: JSON.Parse.consume_whitespace(rest) |> consume_array_contents

    def consume(<< ?[, rest :: binary >>), do: JSON.Parse.consume_whitespace(rest) |> consume_array_contents

    def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def consume([ ]),   do:  {:error, :unexpected_end_of_buffer}
    def consume(json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json }}

    # Array Parsing
    defp consume_array_contents(json) when is_list(json) or is_binary(json), do: consume_array_contents([], json)

    defp consume_array_contents(acc, << ?], rest :: binary >>), do: {:ok, Enum.reverse(acc), rest }
    defp consume_array_contents(acc, [ ?] | rest ]), do: {:ok, Enum.reverse(acc), rest }

    defp consume_array_contents(_, << >> ), do: { :error,  :unexpected_end_of_buffer }
    defp consume_array_contents(_, [] ), do: { :error, :unexpected_end_of_buffer }

    defp consume_array_contents(acc, json) do
      case JSON.Parse.consume_whitespace(json) |> JSON.Parse.Value.consume do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value } ->
          after_value = JSON.Parse.consume_whitespace(after_value)
          case after_value  do
            [ ?, | after_comma ] -> consume_array_contents([ value | acc ], JSON.Parse.consume_whitespace(after_comma))
            << ?, , after_comma :: binary >> -> consume_array_contents([ value | acc ], JSON.Parse.consume_whitespace(after_comma))
            _ ->  consume_array_contents([ value | acc ], after_value)
          end
      end
    end
  end


  defmodule String do
    @doc """
    Consumes a valid JSON string, returns its elixir representation

    ## Examples

        iex> JSON.Parse.String.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.String.consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.String.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.String.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.String.consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.String.consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.String.consume '129245'
        {:error, {:unexpected_token, '129245'} }

        iex> JSON.Parse.String.consume "129245"
        {:error, {:unexpected_token, "129245"} }

        iex> JSON.Parse.String.consume '\\\"7.something\\\"'
        {:ok, "7.something", '' }

        iex> JSON.Parse.String.consume "\\\"7.something\\\""
        {:ok, "7.something", "" }

        iex> JSON.Parse.String.consume "\\\"-88.22suffix\\\" foo bar"
        {:ok, "-88.22suffix", " foo bar" }

        iex> JSON.Parse.String.consume '\\\"-88.22suffix\\\" foo bar'
        {:ok, "-88.22suffix", ' foo bar' }

        iex> JSON.Parse.String.consume "\\\"star -> \\\\u272d <- star\\\""
        {:ok, "star -> ✭ <- star", "" }

    """
    def consume([ ?" | rest ]), do: consume_string_contents(rest, [])
    def consume(<< ?" :: utf8 , rest :: binary >>), do: consume_string_contents(rest, [])

    def consume([ ]),   do:  {:error, :unexpected_end_of_buffer}
    def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def consume(json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json }}

    #stop conditions
    defp consume_string_contents([], _), do: {:error, :unexpected_end_of_buffer}

    defp consume_string_contents([ ?" | rest ], acc), do: { :ok, iolist_to_binary(acc), rest }

    defp consume_string_contents(<< >>, _), do: {:error, :unexpected_end_of_buffer}
    defp consume_string_contents(<< ?" :: utf8, rest :: binary >>, acc), do: { :ok, iolist_to_binary(acc), rest }

    #parsing

    ##iolists
    defp consume_string_contents([ ?\\, ?f  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\f ])
    defp consume_string_contents([ ?\\, ?n  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\n ])
    defp consume_string_contents([ ?\\, ?r  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\r ])
    defp consume_string_contents([ ?\\, ?t  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\t ])
    defp consume_string_contents([ ?\\, ?"  | rest ], acc), do: consume_string_contents(rest, [ acc, ?"  ])
    defp consume_string_contents([ ?\\, ?\\ | rest ], acc), do: consume_string_contents(rest, [ acc, ?\\ ])
    defp consume_string_contents([ ?\\, ?/  | rest ], acc), do: consume_string_contents(rest, [ acc, ?/  ])

    defp consume_string_contents([ ?\\, ?u  | rest ], acc) do
      case JSON.Parse.UnicodeEscape.consume([ ?\\, ?u  | rest ]) do
        { :error, error_info } -> { :error, error_info }
        { :ok, value, rest } -> consume_string_contents(rest, [ acc, value ])
      end
    end

    ##bitstring
    defp consume_string_contents([ char | rest ], acc), do: consume_string_contents(rest, [ acc, char ])

    defp consume_string_contents(<< ?\\, ?f,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\f ])
    defp consume_string_contents(<< ?\\, ?n,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\n ])
    defp consume_string_contents(<< ?\\, ?r,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\r ])
    defp consume_string_contents(<< ?\\, ?t,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\t ])
    defp consume_string_contents(<< ?\\, ?",  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?"  ])
    defp consume_string_contents(<< ?\\, ?\\, rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\\ ])
    defp consume_string_contents(<< ?\\, ?/,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?/  ])

    defp consume_string_contents(<< ?\\, ?u , rest :: binary >>, acc) do
      case JSON.Parse.UnicodeEscape.consume("\\u" <> rest) do
        { :error, error_info } -> { :error, error_info }
        { :ok, value, rest } -> consume_string_contents(rest, [ acc, value ])
      end
    end

    defp consume_string_contents(<< char :: utf8, rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, char ])
  end

  defmodule UnicodeEscape do
    @doc """
    Consumes a JSON Unicode Escaped character, returns its UTF8 representation

    ## Examples

        iex> JSON.Parse.UnicodeEscape.consume ''
        { :error, :unexpected_end_of_buffer }

        iex> JSON.Parse.UnicodeEscape.consume ""
        { :error, :unexpected_end_of_buffer }

        iex> JSON.Parse.UnicodeEscape.consume 'xkcd'
        { :error, {:unexpected_token, 'xkcd'} }

        iex> JSON.Parse.UnicodeEscape.consume "xkcd"
        { :error, {:unexpected_token, "xkcd"} }

        iex> JSON.Parse.UnicodeEscape.consume '\\\\u00df'
        { :ok, "ß", '' }

        iex> JSON.Parse.UnicodeEscape.consume "\\\\u00df"
        { :ok, "ß", "" }

        iex> JSON.Parse.UnicodeEscape.consume "\\\\u00dflalalal"
        { :ok, "ß", "lalalal" }

        iex> JSON.Parse.UnicodeEscape.consume "\\\\u00dflalalal"
        { :ok, "ß", "lalalal" }
    """
    def consume(<< ?\\, ?u , rest :: binary >>) do
      case consume_unicode_escape(rest, 0, 0) do
        { :ok, tentative_codepoint, after_tentative_codepoint} ->
          if Elixir.String.valid_codepoint? tentative_codepoint do
            { :ok, tentative_codepoint, after_tentative_codepoint}
          else
            {:error, { :unexpected_token, << ?\\, ?u, rest >> } }
          end
        { :error, error_info } -> { :error, error_info }
      end
    end

    def consume([?\\, ?u | rest]) do
      case consume_unicode_escape(rest, 0, 0) do
        { :ok, tentative_codepoint, after_tentative_codepoint} ->
          if Elixir.String.valid_codepoint? tentative_codepoint do
            { :ok, tentative_codepoint, after_tentative_codepoint}
          else
            {:error, { :unexpected_token, [?\\, ?u | rest] } }
          end
        { :error, error_info } -> { :error, error_info }
      end
    end

    def consume([ ]),   do:  {:error, :unexpected_end_of_buffer}
    def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def consume(json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json }}

    #The only OK stop condition (consumed 4 expected chars successfully)
    defp consume_unicode_escape(json, acc, chars_consumed) when (is_list(json) or is_binary(json)) and 4 === chars_consumed do
      { :ok, << acc :: utf8 >>, json }
    end

    # there are not enough chars to consume the expected unicode escape
    defp consume_unicode_escape([], _, _), do: {:error, :unexpected_end_of_buffer}
    defp consume_unicode_escape(<< >>, _, _), do: {:error, :unexpected_end_of_buffer}

    defp consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?0..?9 do
      consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1)
    end

    defp consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?a..?f do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1)
    end

    defp consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?A..?F do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1)
    end

    defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?0..?9 do
      consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1)
    end

    defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?a..?f do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1)
    end

    defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?A..?F do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1)
    end

    #unexpected token stop condition, other stop conditions not met
    defp consume_unicode_escape(binary_or_iolist, _, _), do: {:error, {:unexpected_token, binary_or_iolist}}
  end

  defmodule Number do
    @doc """
    Consumes a valid JSON numerical value, returns its elixir numerical representation

    ## Examples

        iex> JSON.Parse.Number.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Number.consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Number.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Number.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Number.consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.Number.consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.Number.consume '129245'
        {:ok, 129245, '' }

        iex> JSON.Parse.Number.consume "129245"
        {:ok, 129245, "" }

        iex> JSON.Parse.Number.consume '7.something'
        {:ok, 7, '.something' }

        iex> JSON.Parse.Number.consume "7.something"
        {:ok, 7, ".something" }

        iex> JSON.Parse.Number.consume '7.4566something'
        {:ok, 7.4566, 'something' }

        iex> JSON.Parse.Number.consume "7.4566something"
        {:ok, 7.4566, "something" }

        iex> JSON.Parse.Number.consume '-88.22suffix'
        {:ok, -88.22, 'suffix' }

        iex> JSON.Parse.Number.consume "-88.22suffix"
        {:ok, -88.22, "suffix" }

        iex> JSON.Parse.Number.consume '-12e4and then some'
        {:ok, -1.2e+5, 'and then some' }

        iex> JSON.Parse.Number.consume "-12e4and then some"
        {:ok, -1.2e+5, "and then some" }

        iex> JSON.Parse.Number.consume '7842490016E-12-and more'
        {:ok, 7.842490016e-3, '-and more' }

        iex> JSON.Parse.Number.consume "7842490016E-12-and more"
        {:ok, 7.842490016e-3, "-and more" }
    """
    def consume([ ?- , number | rest]) when number in ?0..?9 do
      consume([number | rest]) |> negate
    end

    def consume(<< ?- , number :: utf8 ,  rest :: binary >>) when number in ?0..?9 do
      consume(<< number :: utf8, rest :: binary>>) |> negate
    end

    def consume([ number | rest]) when number in ?0..?9 do
      iolist_to_integer([ number | rest])
        |> add_fractional
        |> apply_exponent
    end

    def consume(<< ?- , number :: utf8, rest :: binary >>) when number in ?0..?9 do
      consume(<< number :: utf8,  rest :: binary >>) |> negate
    end

    def consume(<< number :: utf8 ,  rest :: binary >>) when number in ?0..?9 do
      bitstring_to_integer(<< number :: utf8, rest :: binary >>)
        |> add_fractional
        |> apply_exponent
    end

    def consume([ ]), do:  {:error, :unexpected_end_of_buffer}
    def consume(<< >>), do:  {:error, :unexpected_end_of_buffer}
    def consume(json) when is_list(json) or is_binary(json), do: {:error, { :unexpected_token, json }}

    defp negate({:error, error_info}), do: {:error, error_info}
    defp negate({:ok, number, json }) when is_list(json) or is_binary(json), do: {:ok, -1 * number, json }

    defp add_fractional({:error, error_info}), do: {:error, error_info}

    defp add_fractional({:ok, acc, [ ?., c | rest ] }) when c in ?0..?9 do
      { fractional, rest } = consume_fractional([ c | rest ], 0, 10.0)
      {:ok, acc + fractional, rest }
    end

    defp add_fractional({:ok, acc, << ?., c :: utf8, rest :: binary >> }) when c in ?0..?9 do
      { fractional, rest } = consume_fractional(<< c :: utf8,  rest :: binary >>, 0, 10.0)
      {:ok, acc + fractional, rest }
    end

    # ensures the following behavior - JSON.Parse.Number.consume '-88.22suffix' - {:ok, -88.22, 'suffix' }
    defp add_fractional({:ok, acc, json }) when is_list(json) or is_binary(json), do: {:ok, acc, json }

    defp consume_fractional([ number | rest ], acc, power) when number in ?0..?9 do
      consume_fractional(rest, acc + (number - ?0) / power, power * 10)
    end

    defp consume_fractional(<< number :: utf8, rest :: binary >>, acc, power) when number in ?0..?9 do
      consume_fractional(rest, acc + (number - ?0) / power, power * 10)
    end

    # ensures the following behavior - JSON.Parse.Number.consume '-88.22suffix' - {:ok, -88.22, 'suffix' }
    defp consume_fractional(json, acc , _) when is_list(json) or is_binary(json), do: { acc, json }

    defp apply_exponent({:error, error_info}), do: { :error, error_info }

    defp apply_exponent({:ok, acc, [ exponent | rest ] }) when exponent in [?e, ?E] do
      case iolist_to_integer(rest) do
        { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
        { :error, error_info } -> { :error, error_info }
      end
    end

    defp apply_exponent({:ok, acc, << exponent :: utf8, rest :: binary >> }) when exponent in [?e, ?E] do
      case bitstring_to_integer(rest) do
        { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
        { :error, error_info } -> { :error, error_info }
      end
    end

    # ensures the following behavior - JSON.Parse.Number.consume "7842490016E-12-and more" - {:ok, 7.842490016e-3, '-and more' }
    defp apply_exponent({:ok, acc, json }) when is_list(json) or is_binary(json), do: {:ok, acc, json }

    # mini-wrapper around Elixir.String.to_integer
    defp bitstring_to_integer(<< >>), do: {:error,  :unexpected_end_of_buffer}

    defp bitstring_to_integer(bitstring) when is_binary(bitstring) do
      case Elixir.String.to_integer(bitstring) do
        :error -> {:error, {:unexpected_token, bitstring} }
        { result, rest } -> {:ok, result, rest}
      end
    end

    # mini-wrapper around :string.to_integer
    defp iolist_to_integer([]), do: {:error, :unexpected_end_of_buffer}

    defp iolist_to_integer(iolist) when is_list(iolist) do
      case :string.to_integer(iolist) do
        { :error, _ } -> {:error, {:unexpected_token, iolist} }
        { result, rest } -> {:ok, result, rest}
      end
    end
  end
end
