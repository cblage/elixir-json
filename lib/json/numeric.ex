defmodule JSON.Numeric do

  @moduledoc """
  Like `String.to_integer`, but for hexadecimal numbers.

  Examples

      iex> JSON.Numeric.to_integer_from_hex ""
      :error

      iex> JSON.Numeric.to_integer_from_hex "xkcd"
      :error

      iex> JSON.Numeric.to_integer_from_hex "94"
      { 148, "" }

      iex> JSON.Numeric.to_integer_from_hex "C2freezing"
      { 3119, "reezing" }
  """
  def to_integer_from_hex(s) do
    case Regex.match?(%r{^[0-9a-fA-F]}, s) do
      true -> to_integer_from_hex(s, 0)
      false -> :error
    end
  end

  defp to_integer_from_hex(s, sum) do
    case s do
      << c, rest :: binary >> when c in ?0..?9 ->
        to_integer_from_hex rest, 16 * sum + c - ?0
      << c, rest :: binary >> when c in ?a..?f ->
        to_integer_from_hex rest, 16 * sum + 10 + c - ?a
      << c, rest :: binary >> when c in ?A..?F ->
        to_integer_from_hex rest, 16 * sum + 10 + c - ?A
      _ ->
        { sum, s }
    end
  end

end
