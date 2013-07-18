defmodule JSON do

  def encode(item) do
    JSON.Encode.to_json(item)
  end

  def decode(item) do
    try do
      {:ok, JSON.decode!(item)}
    rescue
      error -> {:error, error}
    end
  end
  
  def decode!(item) do
    JSON.Decode.from_json(item)
  end

end
