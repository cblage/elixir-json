defmodule JSON.Parser.Number do
  @moduledoc """
  Implements a JSON Numeber Parser for Bitstring values
  """

  @doc """
  parses a valid JSON numerical value, returns its elixir numerical representation

  ## Examples

      iex> JSON.Parser.Number.parse ""
      {:error, :unexpected_end_of_buffer}

      iex> JSON.Parser.Number.parse "face0ff"
      {:error, {:unexpected_token, "face0ff"}}

      iex> JSON.Parser.Number.parse "-hello"
      {:error, {:unexpected_token, "hello"}}

      iex> JSON.Parser.Number.parse "129245"
      {:ok, 129245, ""}

      iex> JSON.Parser.Number.parse "7.something"
      {:ok, 7, ".something"}

      iex> JSON.Parser.Number.parse "7.4566something"
      {:ok, 7.4566, "something"}

      iex> JSON.Parser.Number.parse "-88.22suffix"
      {:ok, -88.22, "suffix"}

      iex> JSON.Parser.Number.parse "-12e4and then some"
      {:ok, -1.2e+5, "and then some"}

      iex> JSON.Parser.Number.parse "7842490016E-12-and more"
      {:ok, 7.842490016e-3, "-and more"}
  """
  def parse(<<?-, rest::binary>>) do
    case parse(rest) do
      {:ok, number, json} -> {:ok, -1 * number, json}
      {:error, error_info} -> {:error, error_info}
    end
  end

  def parse(binary) do
    case binary do
      <<number::utf8, _::binary>> when number in ?0..?9 ->
        binary |> to_integer |> add_fractional |> apply_exponent

      <<>> ->
        {:error, :unexpected_end_of_buffer}

      _ ->
        {:error, {:unexpected_token, binary}}
    end
  end

  # error condition
  defp add_fractional({:error, error_info}), do: {:error, error_info}

  # stop condition
  defp add_fractional({:ok, acc, bin}) do
    case bin do
      <<?., after_dot::binary>> ->
        case after_dot do
          <<c::utf8, _::binary>> when c in ?0..?9 ->
            {fractional, rest} = parse_fractional(after_dot, 0, 10.0)
            {:ok, acc + fractional, rest}

          _ ->
            {:ok, acc, bin}
        end

      _ ->
        {:ok, acc, bin}
    end
  end

  defp parse_fractional(<<number::utf8, rest::binary>>, acc, power) when number in ?0..?9 do
    parse_fractional(rest, acc + (number - ?0) / power, power * 10)
  end

  defp parse_fractional(json, acc, _) when is_binary(json), do: {acc, json}

  # error condition
  defp apply_exponent({:error, error_info}), do: {:error, error_info}

  # stop condition
  defp apply_exponent({:ok, acc, <<exponent::utf8, rest::binary>>}) when exponent in 'eE' do
    case to_integer(rest) do
      {:ok, power, rest} -> {:ok, acc * :math.pow(10, power), rest}
      {:error, error_info} -> {:error, error_info}
    end
  end

  defp apply_exponent({:ok, acc, json}), do: {:ok, acc, json}

  defp to_integer(<<>>), do: {:error, :unexpected_end_of_buffer}

  defp to_integer(binary) do
    case Integer.parse(binary) do
      {result, rest} when is_integer(result) and is_binary(rest) -> {:ok, result, rest}
      :error -> {:error, {:unexpected_token, binary}}
    end
  end
end
