defmodule JSON.Parse.Bitstring do

  defmodule Whitespace do
    #32 = ascii space, cleaner than using "? ", I think
    @acii_space 32

    @doc """
    Consumes valid JSON whitespace if it exists, returns the rest of the buffer

    ## Examples

        iex> JSON.Parse.Bitstring.Whitespace.consume ""
        ""

        iex> JSON.Parse.Bitstring.Whitespace.consume "xkcd"
        "xkcd"

        iex> JSON.Parse.Bitstring.Whitespace.consume "  \\t\\r lalala "
        "lalala "

        iex> JSON.Parse.Bitstring.Whitespace.consume " \\n\\t\\n fooo \\u00dflalalal "
        "fooo \\u00dflalalal "
    """
    def consume(<< @acii_space :: utf8, rest :: binary >>), do: consume(rest)
    def consume(<< ?\t :: utf8, rest :: binary >>), do: consume(rest)
    def consume(<< ?\r :: utf8, rest :: binary >>), do: consume(rest)
    def consume(<< ?\n :: utf8, rest :: binary >>), do: consume(rest)
    def consume(bitstring) when is_binary(bitstring), do: bitstring
  end

  defmodule Value do

    @doc """
    Consumes a valid JSON value, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Bitstring.Value.consume "", JSON.Collector.new
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Bitstring.Value.consume "face0ff", JSON.Collector.new
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Bitstring.Value.consume "-hello", JSON.Collector.new
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.Bitstring.Value.consume "129245", JSON.Collector.new
        {:ok, 129245, "" }

        iex> JSON.Parse.Bitstring.Value.consume "7.something", JSON.Collector.new
        {:ok, 7, ".something" }

        iex> JSON.Parse.Bitstring.Value.consume "-88.22suffix", JSON.Collector.new
        {:ok, -88.22, "suffix" }

        iex> JSON.Parse.Bitstring.Value.consume "-12e4and then some", JSON.Collector.new
        {:ok, -1.2e+5, "and then some" }

        iex> JSON.Parse.Bitstring.Value.consume "7842490016E-12-and more", JSON.Collector.new
        {:ok, 7.842490016e-3, "-and more" }

        iex> JSON.Parse.Bitstring.Value.consume "null", JSON.Collector.new
        {:ok, nil, ""}

        iex> JSON.Parse.Bitstring.Value.consume "false", JSON.Collector.new
        {:ok, false, "" }

        iex> JSON.Parse.Bitstring.Value.consume "true", JSON.Collector.new
        {:ok, true, "" }

        iex> JSON.Parse.Bitstring.Value.consume "\\\"7.something\\\"", JSON.Collector.new
        {:ok, "7.something", "" }

        iex> JSON.Parse.Bitstring.Value.consume "\\\"-88.22suffix\\\" foo bar", JSON.Collector.new
        {:ok, "-88.22suffix", " foo bar" }

        iex> JSON.Parse.Bitstring.Value.consume "\\\"star -> \\\\u272d <- star\\\"", JSON.Collector.new
        {:ok, "star -> ✭ <- star", "" }

        iex> JSON.Parse.Bitstring.Value.consume "[]", JSON.Collector.new
        {:ok, [], "" }

        iex> JSON.Parse.Bitstring.Value.consume "[\\\"foo\\\", 1, 2, 1.5] lala", JSON.Collector.new
        {:ok, ["foo", 1, 2, 1.5], " lala" }

        iex> JSON.Parse.Bitstring.Value.consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal", JSON.Collector.new
        {:ok, Enum.into([{"result", "this will be a elixir result"}], HashDict.new), " lalal"}
    """
    def consume(<< ?[, _ :: binary >> = bin, collector), do: JSON.Parse.Bitstring.Array.consume(bin, collector)
    def consume(<< ?{, _ :: binary >> = bin, collector), do: JSON.Parse.Bitstring.Object.consume(bin, collector)
    def consume(<< ?", _ :: binary >> = bin, _), do: JSON.Parse.Bitstring.String.consume(bin)

    def consume(<< ?- , number :: utf8, _ :: binary  >> = bin, _) when number in ?0..?9 do
      JSON.Parse.Bitstring.Number.consume(bin)
    end

    def consume(<< number :: utf8, _ :: binary >> = bin, _) when number in ?0..?9 do
      JSON.Parse.Bitstring.Number.consume(bin)
    end

    def consume(<< ?n, ?u, ?l, ?l, rest :: binary >>, _), do: { :ok, nil,   rest }
    def consume(<< ?t, ?r, ?u, ?e, rest :: binary >>, _), do: { :ok, true,  rest }
    def consume(<< ?f, ?a, ?l, ?s, ?e, rest :: binary >>, _), do: { :ok, false, rest }

    def consume(<< >>, _), do:  {:error, :unexpected_end_of_buffer}
    def consume(json, _), do: {:error, { :unexpected_token, json }}
  end

  defmodule Object do
    @doc """
    Consumes a valid JSON object value, returns its elixir representation based on the provided Collector

    ## Examples

        iex> JSON.Parse.Bitstring.Object.consume "", JSON.Collector.new
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Bitstring.Object.consume "face0ff", JSON.Collector.new
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Bitstring.Object.consume "[] ", JSON.Collector.new
        {:error, {:unexpected_token, "[] "}}

        iex> JSON.Parse.Bitstring.Object.consume "[]", JSON.Collector.new
        {:error, {:unexpected_token, "[]"}}

        iex> JSON.Parse.Bitstring.Object.consume "[\\\"foo\\\", 1, 2, 1.5] lala", JSON.Collector.new
        {:error, {:unexpected_token, "[\\\"foo\\\", 1, 2, 1.5] lala"}}

        iex> JSON.Parse.Bitstring.Object.consume "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal", JSON.Collector.new
        {:ok, Enum.into([{"result", "this will be a elixir result"}], HashDict.new), " lalal"}
    """
    def consume(<< ?{, rest :: binary >>, collector) do
      JSON.Parse.Bitstring.Whitespace.consume(rest)
        |> consume_object_contents(collector)
    end

    def consume(<< >>, _), do: { :error, :unexpected_end_of_buffer }
    def consume(json, _),  do: { :error, { :unexpected_token, json } }

    # Object Parsing
    defp consume_object_key(json) do
      case JSON.Parse.Bitstring.String.consume(json) do
        {:error, error_info} -> {:error, error_info}
        {:ok, key, after_key } ->
          case JSON.Parse.Bitstring.Whitespace.consume(after_key) do
            << ?:,  after_colon :: binary >> ->
              { :ok, key, JSON.Parse.Bitstring.Whitespace.consume(after_colon) }
            << >> ->
              { :error, :unexpected_end_of_buffer}
            _ ->
              { :error, { :unexpected_token, JSON.Parse.Bitstring.Whitespace.consume(after_key) } }
          end
      end
    end

    defp consume_object_value(acc, key, after_key, collector) do
      case JSON.Parse.Bitstring.Value.consume(after_key, collector) do
        { :error, error_info } -> { :error, error_info }
        { :ok, value, after_value } ->
          acc = collector.object.put(acc, key, value)
          after_value = JSON.Parse.Bitstring.Whitespace.consume(after_value)
          case after_value do
            << ?,, after_comma :: binary >> ->
              consume_object_contents acc, JSON.Parse.Bitstring.Whitespace.consume(after_comma), collector
            _  ->
              consume_object_contents acc, after_value, collector
          end
      end
    end

    defp consume_object_contents(json, collector), do: consume_object_contents(collector.object.new, json, collector)

    defp consume_object_contents(acc, << ?", _ :: binary >> = bin, collector) do
      case consume_object_key(bin) do
        { :error, error_info }  -> { :error, error_info }
        { :ok, key, after_key } -> consume_object_value(acc, key, after_key, collector)
      end
    end

    defp consume_object_contents(acc, << ?}, rest :: binary >>, collector), do: { :ok, collector.object.close(acc), rest }

    defp consume_object_contents(_, << >>, _), do: { :error, :unexpected_end_of_buffer }
    defp consume_object_contents(_, json, _), do: { :error, { :unexpected_token, json } }
  end

  defmodule Array do
    @doc """
    Consumes a valid JSON array value, returns its elixir list representation

    ## Examples

        iex> JSON.Parse.Bitstring.Array.consume "", JSON.Collector.new
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Bitstring.Array.consume "[1, 2 ", JSON.Collector.new
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Bitstring.Array.consume "face0ff", JSON.Collector.new
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Bitstring.Array.consume "[] lala", JSON.Collector.new
        {:ok, [], " lala" }

        iex> JSON.Parse.Bitstring.Array.consume "[]", JSON.Collector.new
        {:ok, [], "" }

        iex> JSON.Parse.Bitstring.Array.consume "[\\\"foo\\\", 1, 2, 1.5] lala", JSON.Collector.new
        {:ok, ["foo", 1, 2, 1.5], " lala" }
    """
    def consume(<< ?[, rest :: binary >>, collector) do
      JSON.Parse.Bitstring.Whitespace.consume(rest) |> consume_array_contents(collector)
    end

    def consume(<< >>, _), do:  { :error, :unexpected_end_of_buffer }
    def consume(json, _),  do: { :error, { :unexpected_token, json } }


    defp consume_array_contents(json, collector) when is_binary(json), do: consume_array_contents(collector.array.new, json, collector)

    defp consume_array_contents(acc, << ?], rest :: binary >>, collector), do: { :ok, collector.array.close(acc), rest }
    defp consume_array_contents(_, << >>, _), do: { :error,  :unexpected_end_of_buffer }

    defp consume_array_contents(acc, json, collector) do
      case JSON.Parse.Bitstring.Whitespace.consume(json) |> JSON.Parse.Bitstring.Value.consume(collector) do
        { :error, error_info } -> { :error, error_info }
        {:ok, value, after_value } ->
          after_value = JSON.Parse.Bitstring.Whitespace.consume(after_value)
          case after_value do
            << ?, , after_comma :: binary >> ->
              consume_array_contents(collector.array.put(acc, value), JSON.Parse.Bitstring.Whitespace.consume(after_comma), collector)
            _ ->
              consume_array_contents(collector.array.put(acc, value), after_value, collector)
          end
      end
    end
  end


  defmodule String do
    @doc """
    Consumes a valid JSON string, returns its elixir representation

    ## Examples

        iex> JSON.Parse.Bitstring.String.consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Bitstring.String.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Bitstring.String.consume "-hello"
        {:error, {:unexpected_token, "-hello"} }

        iex> JSON.Parse.Bitstring.String.consume "129245"
        {:error, {:unexpected_token, "129245"} }

        iex> JSON.Parse.Bitstring.String.consume "\\\"7.something\\\""
        {:ok, "7.something", "" }

        iex> JSON.Parse.Bitstring.String.consume "\\\"-88.22suffix\\\" foo bar"
        {:ok, "-88.22suffix", " foo bar" }

        iex> JSON.Parse.Bitstring.String.consume "\\\"star -> \\\\u272d <- star\\\""
        {:ok, "star -> ✭ <- star", "" }

        iex> JSON.Parse.Bitstring.String.consume "\\\"\\\\u00df ist wunderbar\\\""
        {:ok, "ß ist wunderbar", "" }

        iex> JSON.Parse.Bitstring.String.consume "\\\"Rafaëlla\\\" foo bar"
        {:ok, "Rafaëlla", " foo bar" }

        iex> JSON.Parse.Bitstring.String.consume "\\\"Éloise woot\\\" Éloise"
        {:ok, "Éloise woot", " Éloise" }
    """
    def consume(<< ?" :: utf8 , rest :: binary >>), do: consume_string_contents(rest, [ ])
    def consume(<< >>), do: { :error, :unexpected_end_of_buffer }
    def consume(json), do: { :error, { :unexpected_token, json } }


    #stop conditions
    defp consume_string_contents(<< >>, _), do: { :error, :unexpected_end_of_buffer }
    defp consume_string_contents(<< ?" :: utf8, rest :: binary >>, acc) do
      case Elixir.String.from_char_data(acc) do
        {:ok, encoded_string } -> { :ok, encoded_string, rest }
        _ -> {:error, { :unexpected_token, rest }}
      end
    end

    #parsing
    defp consume_string_contents(<< ?\\, ?f,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\f ])
    defp consume_string_contents(<< ?\\, ?n,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\n ])
    defp consume_string_contents(<< ?\\, ?r,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\r ])
    defp consume_string_contents(<< ?\\, ?t,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\t ])
    defp consume_string_contents(<< ?\\, ?",  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?"  ])
    defp consume_string_contents(<< ?\\, ?\\, rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?\\ ])
    defp consume_string_contents(<< ?\\, ?/,  rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, ?/  ])

    defp consume_string_contents(<< ?\\, ?u , rest :: binary >> , acc) do
      case consume_unicode_escape(rest, 0, 0) do
       { :error, error_info } -> { :error, error_info }
       { :ok, decoded_codepoint, after_decoded_codepoint} ->
          case decoded_codepoint do
            << _ ::utf8 >> ->
              consume_string_contents(after_decoded_codepoint, [ acc, decoded_codepoint ])
            _ ->
              { :error, { :unexpected_token, << ?\\, ?u , rest :: binary >> } }
          end
      end
    end

    defp consume_string_contents(<< char :: utf8, rest :: binary >>, acc), do: consume_string_contents(rest, [ acc, char ])


    # The only OK stop condition (consumed 4 expected chars successfully)
    defp consume_unicode_escape(json, acc, chars_consumed) when 4 === chars_consumed do
      { :ok, << acc :: utf8 >>, json }
    end

    defp consume_unicode_escape(<< >>, _, _), do: {:error, :unexpected_end_of_buffer}

    defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?0..?9 do
      consume_unicode_escape(rest, 16 * acc + char - ?0, chars_consumed + 1)
    end

    defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?a..?f do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?a, chars_consumed + 1)
    end

    defp consume_unicode_escape(<< char :: utf8, rest :: binary >>, acc, chars_consumed) when char in ?A..?F do
      consume_unicode_escape(rest, 16 * acc + 10 + char - ?A, chars_consumed + 1)
    end

    defp consume_unicode_escape(json, _, _), do: { :error, { :unexpected_token, json } }
  end

  defmodule Number do
    @doc """
    Consumes a valid JSON numerical value, returns its elixir numerical representation

    ## Examples

        iex> JSON.Parse.Bitstring.Number.consume ""
        {:error, :unexpected_end_of_buffer}

        iex> JSON.Parse.Bitstring.Number.consume "face0ff"
        {:error, {:unexpected_token, "face0ff"} }

        iex> JSON.Parse.Bitstring.Number.consume "-hello"
        {:error, {:unexpected_token, "hello"} }

        iex> JSON.Parse.Bitstring.Number.consume "129245"
        {:ok, 129245, "" }

        iex> JSON.Parse.Bitstring.Number.consume "7.something"
        {:ok, 7, ".something" }

        iex> JSON.Parse.Bitstring.Number.consume "7.4566something"
        {:ok, 7.4566, "something" }

        iex> JSON.Parse.Bitstring.Number.consume "-88.22suffix"
        {:ok, -88.22, "suffix" }

        iex> JSON.Parse.Bitstring.Number.consume "-12e4and then some"
        {:ok, -1.2e+5, "and then some" }

        iex> JSON.Parse.Bitstring.Number.consume "7842490016E-12-and more"
        {:ok, 7.842490016e-3, "-and more" }
    """
    def consume(<< ?- , rest :: binary >>) do
      case consume(rest) do
        { :ok, number, json } -> { :ok, -1 * number, json }
        { :error, error_info } -> { :error, error_info }
      end
    end


    def consume(binary) do
      case binary do
        << number :: utf8 ,  _ :: binary >> when number in ?0..?9 ->
          to_integer(binary) |> add_fractional |> apply_exponent
        << >> ->  { :error, :unexpected_end_of_buffer }
        _  -> { :error, { :unexpected_token, binary } }
      end
    end


    defp add_fractional({ :error, error_info }), do: { :error, error_info }

    defp add_fractional({ :ok, acc, bin })  do
      case bin do
        << ?., after_dot :: binary >>  ->
          case after_dot do
            << c :: utf8, _ :: binary >> when c in ?0..?9 ->
              { fractional, rest } = consume_fractional(after_dot, 0, 10.0)
              { :ok, acc + fractional, rest }
            _ ->
              { :ok, acc, bin }
          end
        _ ->
          { :ok, acc, bin }
      end
    end

    defp consume_fractional(<< number :: utf8, rest :: binary >>, acc, power) when number in ?0..?9 do
      consume_fractional(rest, acc + (number - ?0) / power, power * 10)
    end

    defp consume_fractional(json, acc , _) when is_binary(json), do: { acc, json }


    defp apply_exponent({ :error, error_info }), do: { :error, error_info }

    defp apply_exponent({ :ok, acc, << exponent :: utf8, rest :: binary >> }) when exponent in 'eE' do
      case to_integer(rest) do
        { :ok, power, rest } -> { :ok, acc * :math.pow(10, power), rest }
        { :error, error_info } -> { :error, error_info }
      end
    end

    defp apply_exponent({ :ok, acc, json }), do: { :ok, acc, json }


    defp to_integer(<< >>), do: { :error,  :unexpected_end_of_buffer }

    defp to_integer(binary) do
      case Integer.parse(binary) do
        { :error, _ } -> { :error, { :unexpected_token, binary } }
        { result, rest } -> {:ok, result, rest}
      end
    end
  end
end
