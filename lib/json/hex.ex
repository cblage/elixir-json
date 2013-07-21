defmodule JSON.Hex do

  def is_hex?(""), do: true

  def is_hex?(<< c, rest :: binary >>) do
    valid = List.concat [Enum.to_list(?0..?9), Enum.to_list(?a..?f), Enum.to_list(?A..?F)]
    Enum.member?(valid, c) && is_hex?(rest)
  end

  def to_integer(s) do
    to_integer(s, 0)
  end

  defp to_integer("", sum) do
    sum
  end

  defp to_integer(<< c, rest :: binary >>, sum) do
    to_integer(rest, sum * 16 + decimal_digit(c))
  end

  defp decimal_digit(c) when c in ?0..?9, do: c - ?0
  defp decimal_digit(c) when c in ?a..?f, do: 10 + c - ?a
  defp decimal_digit(c) when c in ?A..?F, do: 10 + c - ?A

end
