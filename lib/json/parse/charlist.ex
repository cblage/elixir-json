defmodule JSON.Parse.Charlist do

  defmodule Whitespace do
    #32 = ascii space, cleaner than using "? ", I think
    @acii_space 32
    
    @doc """
    Consumes valid JSON whitespace if it exists, returns the rest of the buffer

    ## Examples

        iex> JSON.Parse.Charlist.Whitespace.consume ''
        '' 

        iex> JSON.Parse.Charlist.Whitespace.consume 'xkcd'
        'xkcd'

        iex> JSON.Parse.Charlist.Whitespace.consume '  \\t\\r lalala '
        'lalala '

        iex> JSON.Parse.Charlist.Whitespace.consume ' \\n\\t\\n fooo \\u00dflalalal '
        'fooo \\u00dflalalal '
    """
    def consume([ @acii_space | rest ]), do: consume(rest)
    def consume([ ?\t | rest ]), do: consume(rest)
    def consume([ ?\r | rest ]), do: consume(rest)
    def consume([ ?\n | rest ]), do: consume(rest)
    def consume(charlist) when is_list(charlist), do: charlist
  end

  defmodule Value do
    @doc """
    Consumes a valid JSON value, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Charlist.Value.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Charlist.Value.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Charlist.Value.consume '-hello'
        {:error, {:unexpected_token, '-hello'} }
        
        iex> JSON.Parse.Charlist.Value.consume '129245'
        {:ok, 129245, '' }
        
        iex> JSON.Parse.Charlist.Value.consume '7.something'
        {:ok, 7, '.something' }

        iex> JSON.Parse.Charlist.Value.consume '-88.22suffix'
        {:ok, -88.22, 'suffix' }
        
        iex> JSON.Parse.Charlist.Value.consume '-12e4and then some'
        {:ok, -1.2e+5, 'and then some' }
        
        iex> JSON.Parse.Charlist.Value.consume '7842490016E-12-and more'
        {:ok, 7.842490016e-3, '-and more' }
        
        iex> JSON.Parse.Charlist.Value.consume 'null'
        {:ok, nil, '' }

        iex> JSON.Parse.Charlist.Value.consume 'false'
        {:ok, false, '' }
        
        iex> JSON.Parse.Charlist.Value.consume 'true'
        {:ok, true, '' }
        
        iex> JSON.Parse.Charlist.Value.consume '\\\"7.something\\\"'
        {:ok, "7.something", '' }
        
        iex> JSON.Parse.Charlist.Value.consume '\\\"-88.22suffix\\\" foo bar'
        {:ok, "-88.22suffix", ' foo bar' }

        iex> JSON.Parse.Charlist.Value.consume '[]'
        {:ok, [], '' }
        
        iex> JSON.Parse.Charlist.Value.consume '["foo", 1, 2, 1.5] lala'
        {:ok, ["foo", 1, 2, 1.5], ' lala' }

        iex> JSON.Parse.Charlist.Value.consume '{"result": "this will be a elixir result"} lalal'
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), ' lalal'}
    """
    def consume([ ?[ | _ ] = charlist), do: JSON.Parse.Charlist.Array.consume(charlist)
    def consume([ ?{ | _ ] = charlist), do: JSON.Parse.Charlist.Object.consume(charlist)
    def consume([ ?" | _ ] = charlist), do: JSON.Parse.Charlist.String.consume(charlist)
    
    def consume([ ?- , number | _ ] = charlist) when number in ?0..?9 do
        JSON.Parse.Charlist.Number.consume(charlist)
    end

    def consume([ number | _ ] = charlist) when number in ?0..?9 do
        JSON.Parse.Charlist.Number.consume(charlist)
    end
    

    def consume([ ?n, ?u, ?l, ?l  | rest ]),    do: { :ok, nil,   rest }
    def consume([ ?t, ?r, ?u, ?e  | rest ]),    do: { :ok, true,  rest }
    def consume([ ?f, ?a, ?l, ?s, ?e | rest ]), do: { :ok, false, rest }

    def consume([ ]),  do:  {:error, :unexpected_end_of_buffer} 
    def consume(json), do: {:error, { :unexpected_token, json }}      
  end

  defmodule Object do
    @doc """
    Consumes a valid JSON object value, returns its elixir HashDict representation

    ## Examples

        iex> JSON.Parse.Charlist.Object.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Charlist.Object.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }
        
        iex> JSON.Parse.Charlist.Object.consume '[] '
        {:error, {:unexpected_token, '[] '}}
        
        iex> JSON.Parse.Charlist.Object.consume '[]'
        {:error, {:unexpected_token, '[]'}}
        
        iex> JSON.Parse.Charlist.Object.consume '{"result": "this will be a elixir result"} lalal'
        {:ok, HashDict.new([{"result", "this will be a elixir result"}]), ' lalal'}
    """
    def consume([ ?{ | rest ]) do
      JSON.Parse.Charlist.Whitespace.consume(rest) |> consume_object_contents
    end

    def consume([ ]),  do:  {:error, :unexpected_end_of_buffer} 
    def consume(json), do: {:error, { :unexpected_token, json }}

    defp consume_object_key(json) when is_list(json) or is_binary(json) do
      case JSON.Parse.Charlist.String.consume(json) do 
        {:error, error_info} -> {:error, error_info}
        {:ok, key, after_key } ->
          case JSON.Parse.Charlist.Whitespace.consume(after_key) do
            [ ?: | after_colon ] -> {:ok, key, JSON.Parse.Charlist.Whitespace.consume(after_colon)}
            []    -> { :error, :unexpected_end_of_buffer}
            _     -> { :error, {:unexpected_token, JSON.Parse.Charlist.Whitespace.consume(after_key) }}
          end
      end
    end

    defp consume_object_value(acc, key, after_key) do
      case JSON.Parse.Charlist.Value.consume(after_key) do
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value} ->
          acc  = HashDict.put(acc, key, value)
          after_value = JSON.Parse.Charlist.Whitespace.consume(after_value)
          case after_value do
            [ ?, | after_comma ] -> consume_object_contents(acc, JSON.Parse.Charlist.Whitespace.consume(after_comma))
            _ -> consume_object_contents(acc, after_value)
          end
      end
    end
    
    defp consume_object_contents(json), do: consume_object_contents(HashDict.new, json)
    
    defp consume_object_contents(acc, [ ?" | _ ] = list) do
      case consume_object_key(list) do
        {:error, error_info}  -> {:error, error_info}
        {:ok, key, after_key} -> consume_object_value(acc, key, after_key)
      end
    end
    
    defp consume_object_contents(acc, [ ?} | rest ]), do: { :ok, acc, rest }
    
    defp consume_object_contents(_, []), do: {:error, :unexpected_end_of_buffer }
    defp consume_object_contents(_, json), do: {:error, { :unexpected_token, json } }
  end

  defmodule Array do
    @doc """
    Consumes a valid JSON array value, returns its elixir list representation

    ## Examples

        iex> JSON.Parse.Charlist.Array.consume ''
        {:error, :unexpected_end_of_buffer}
        
        iex> JSON.Parse.Charlist.Array.consume '[1, 2 '
        {:error, :unexpected_end_of_buffer}
        
        iex> JSON.Parse.Charlist.Array.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Charlist.Array.consume '[] lala'
        {:ok, [], ' lala' }

        iex> JSON.Parse.Charlist.Array.consume '[]'
        {:ok, [], '' }
        
        iex> JSON.Parse.Charlist.Array.consume '["foo", 1, 2, 1.5] lala'
        {:ok, ["foo", 1, 2, 1.5], ' lala' }
    """
    def consume([ ?[ | rest ]) do 
      JSON.Parse.Charlist.Whitespace.consume(rest) |> consume_array_contents
    end
    def consume([ ]),  do:  {:error, :unexpected_end_of_buffer} 
    def consume(json), do: {:error, { :unexpected_token, json }}
    
   
    # Array Parsing

    defp consume_array_contents(json) when is_list(json), do: consume_array_contents([], json)
    
    defp consume_array_contents(acc, [ ?] | rest ]), do: {:ok, Enum.reverse(acc), rest }
    defp consume_array_contents(_, [] ), do: { :error, :unexpected_end_of_buffer }

    defp consume_array_contents(acc, json) do
      case JSON.Parse.Charlist.Whitespace.consume(json) |> JSON.Parse.Charlist.Value.consume do 
        {:error, error_info} -> {:error, error_info}
        {:ok, value, after_value } ->
          after_value = JSON.Parse.Charlist.Whitespace.consume(after_value)
          case after_value  do
            [ ?, | after_comma ] -> 
              consume_array_contents([ value | acc ], JSON.Parse.Charlist.Whitespace.consume(after_comma))
            _ ->  
              consume_array_contents([ value | acc ], after_value)
          end
      end
    end
  end


  defmodule String do
    @doc """
    Consumes a valid JSON string, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Charlist.String.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Charlist.String.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Charlist.String.consume '-hello'
        {:error, {:unexpected_token, '-hello'} }

        iex> JSON.Parse.Charlist.String.consume '129245'
        {:error, {:unexpected_token, '129245'} }
        
        iex> JSON.Parse.Charlist.String.consume '\\\"7.something\\\"'
        {:ok, "7.something", '' }

        iex> JSON.Parse.Charlist.String.consume '\\\"-88.22suffix\\\" foo bar'
        {:ok, "-88.22suffix", ' foo bar' }
  
    """
    def consume([ ?" | rest ]), do: consume_string_contents(rest, [])
    def consume([ ]),  do:  {:error, :unexpected_end_of_buffer} 
    def consume(json), do: {:error, { :unexpected_token, json }}
    

    #stop conditions
    defp consume_string_contents([], _), do: {:error, :unexpected_end_of_buffer}
    defp consume_string_contents([ ?" | rest ], acc), do: { :ok, iolist_to_binary(acc), rest }

    #parsing
    defp consume_string_contents([ ?\\, ?f  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\f ])
    defp consume_string_contents([ ?\\, ?n  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\n ])
    defp consume_string_contents([ ?\\, ?r  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\r ])
    defp consume_string_contents([ ?\\, ?t  | rest ], acc), do: consume_string_contents(rest, [ acc, ?\t ])
    defp consume_string_contents([ ?\\, ?"  | rest ], acc), do: consume_string_contents(rest, [ acc, ?"  ])
    defp consume_string_contents([ ?\\, ?\\ | rest ], acc), do: consume_string_contents(rest, [ acc, ?\\ ])
    defp consume_string_contents([ ?\\, ?/  | rest ], acc), do: consume_string_contents(rest, [ acc, ?/  ])
    
    defp consume_string_contents([ ?\\, ?u  | rest ] = list, acc) do 
      case JSON.Parse.Charlist.UnicodeEscape.consume(list) do 
        { :error, error_info } -> { :error, error_info }
        { :ok, value, rest } -> consume_string_contents(rest, [ acc, value ])
      end 
    end

    defp consume_string_contents([ char | rest ], acc), do: consume_string_contents(rest, [ acc, char ])   
    
  end  

  defmodule UnicodeEscape do
    @doc """
    Consumes a JSON Unicode Escaped character, returns its UTF8 representation

    ## Examples

        iex> JSON.Parse.Charlist.UnicodeEscape.consume ''
        { :error, :unexpected_end_of_buffer } 

        iex> JSON.Parse.Charlist.UnicodeEscape.consume 'xkcd'
        { :error, {:unexpected_token, 'xkcd'} }

        iex> JSON.Parse.Charlist.UnicodeEscape.consume '\\\\u00df'
        { :ok, "ß", '' }
        
        iex> JSON.Parse.Charlist.UnicodeEscape.consume '\\\\u00dflalalal'
        { :ok, "ß", 'lalalal' }

    """
    def consume([?\\, ?u | rest]) do 
      case consume_unicode_escape(rest, 0, 0) do 
        { :ok, tentative_codepoint, after_tentative_codepoint} ->
          case tentative_codepoint do 
            << _ ::utf8 >> -> { :ok, tentative_codepoint, after_tentative_codepoint}
            _ -> {:error, { :unexpected_token, [?\\, ?u | rest]} } #copying only in case of error
          end
        { :error, error_info } -> { :error, error_info }
      end
    end

    def consume([ ]),   do:  {:error, :unexpected_end_of_buffer} 
    def consume(json) when is_list(json), do: {:error, { :unexpected_token, json }}
    
    defp consume_unicode_escape(json, acc, chars_consumed) when 4 === chars_consumed do
      { :ok, << acc :: utf8 >>, json }
    end

    defp consume_unicode_escape([], _, _), do: {:error, :unexpected_end_of_buffer}
    
    defp consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?0..?9 do
      consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1) 
    end

    defp consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?a..?f do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1) 
    end

    defp consume_unicode_escape([char | rest], acc, chars_consumed) when char in ?A..?F do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1) 
    end
  
    defp consume_unicode_escape(json, _, _), do: {:error, {:unexpected_token, json}}
  end

  defmodule Number do
    @doc """
    Consumes a valid JSON numerical value, returns its elixir numerical representation

    ## Examples

        iex> JSON.Parse.Charlist.Number.consume ''
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Charlist.Number.consume 'face0ff'
        {:error, {:unexpected_token, 'face0ff'} }

        iex> JSON.Parse.Charlist.Number.consume '-hello'
        {:error, {:unexpected_token, 'hello'} }

        iex> JSON.Parse.Charlist.Number.consume '129245'
        {:ok, 129245, '' }

        iex> JSON.Parse.Charlist.Number.consume '7.something'
        {:ok, 7, '.something' }
        
        iex> JSON.Parse.Charlist.Number.consume '7.4566something'
        {:ok, 7.4566, 'something' }

        iex> JSON.Parse.Charlist.Number.consume '-88.22suffix'
        {:ok, -88.22, 'suffix' }

        iex> JSON.Parse.Charlist.Number.consume '-12e4and then some'
        {:ok, -1.2e+5, 'and then some' }

        iex> JSON.Parse.Charlist.Number.consume '7842490016E-12-and more'
        {:ok, 7.842490016e-3, '-and more' }
    """
    def consume([ ?- | rest]), do: consume(rest) |> negate
    
    def consume([ number | rest]) when number in ?0..?9 do
      iolist_to_integer([ number | rest]) |> add_fractional |> apply_exponent
    end

    def consume([ ]), do:  {:error, :unexpected_end_of_buffer} 
    def consume(json) when is_list(json), do: {:error, { :unexpected_token, json }}

    #fractional
    defp add_fractional({:error, error_info}), do: {:error, error_info}

    defp add_fractional({:ok, acc, [ ?., c | rest ] }) when c in ?0..?9 do
      { fractional, rest } = consume_fractional([ c | rest ], 0, 10.0)
      {:ok, acc + fractional, rest }
    end

    defp add_fractional({:ok, acc, json }) when is_list(json), do: {:ok, acc, json }

    defp consume_fractional([ number | rest ], acc, power) when number in ?0..?9 do
      consume_fractional(rest, acc + (number - ?0) / power, power * 10)
    end
    
    defp consume_fractional(json, acc , _) when is_list(json), do: { acc, json }


    #exponent    
    defp apply_exponent({:error, error_info}), do: { :error, error_info }
    
    defp apply_exponent({:ok, acc, [ exponent | rest ] }) when exponent in 'eE' do
      case iolist_to_integer(rest) do
        { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
        { :error, error_info } -> { :error, error_info }
      end
    end

    defp apply_exponent({:ok, acc, json }) when is_list(json), do: {:ok, acc, json }
    
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
