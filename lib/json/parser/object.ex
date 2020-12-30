defmodule JSON.Parser.Object do
  @moduledoc """
  Implements a JSON Object Parser for Bitstring values
  """

  alias JSON.Parser, as: Parser

  @doc """
  parses a valid JSON object value, returns its elixir representation

  ## Examples

      iex> JSON.Parser.Object.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Object.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Parser.Object.parse "[] "
      {:error, {:unexpected_token, "[] "}}

      iex> JSON.Parser.Object.parse "[]"
      {:error, {:unexpected_token, "[]"}}

      iex> JSON.Parser.Object.parse "[\\\"foo\\\", 1, 2, 1.5] lala"
      {:error, {:unexpected_token, "[\\\"foo\\\", 1, 2, 1.5] lala"}}

      iex> JSON.Parser.Object.parse "{\\\"result\\\": \\\"this will be a elixir result\\\"} lalal"
      {:ok, Enum.into([{"result", "this will be a elixir result"}], Map.new), " lalal"}
  """
  def parse(<<?{, rest::binary>>) do
    rest
    |> String.trim()
    |> parse_object_contents()
  end

  def parse(<<>>), do: {:error, :unexpected_end_of_buffer}
  def parse(json), do: {:error, {:unexpected_token, json}}

  # Object Parsing
  defp parse_object_key(json) do
    case Parser.String.parse(json) do
      {:error, error_info} ->
        {:error, error_info}

      {:ok, key, after_key} ->
        case String.trim(after_key) do
          <<?:, after_colon::binary>> ->
            {:ok, key, String.trim(after_colon)}

          <<>> ->
            {:error, :unexpected_end_of_buffer}

          _ ->
            {:error, {:unexpected_token, String.trim(after_key)}}
        end
    end
  end

  defp parse_object_value(acc, key, after_key) do
    case Parser.parse(after_key) do
      {:error, error_info} ->
        {:error, error_info}

      {:ok, value, after_value} ->
        acc = Map.put(acc, key, value)

        after_value
        |> String.trim()
        |> case do
          <<?,, after_comma::binary>> ->
            parse_object_contents(acc, String.trim(after_comma))

          rest ->
            parse_object_contents(acc, rest)
        end
    end
  end

  defp parse_object_contents(json), do: parse_object_contents(Map.new(), json)

  defp parse_object_contents(acc, <<?", _::binary>> = bin) do
    case parse_object_key(bin) do
      {:error, error_info} -> {:error, error_info}
      {:ok, key, after_key} -> parse_object_value(acc, key, after_key)
    end
  end

  defp parse_object_contents(acc, <<?}, rest::binary>>), do: {:ok, acc, rest}
  defp parse_object_contents(_, <<>>), do: {:error, :unexpected_end_of_buffer}
  defp parse_object_contents(_, json), do: {:error, {:unexpected_token, json}}
end
