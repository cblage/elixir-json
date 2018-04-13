defmodule JSON.Decoder.Error do
  @moduledoc """
  Thrown when an unknown decoder error happens
  """
  defexception message: "Invalid JSON - unknown error"
end

defmodule JSON.Decoder.UnexpectedEndOfBufferError do
  @moduledoc """
  Thrown when the json payload is incomplete
  """
  defexception message: "Invalid JSON - unexpected end of buffer"
end

defmodule JSON.Decoder.UnexpectedTokenError do
  @moduledoc """
  Thrown when the json payload is invalid
  """
  defexception token: nil

  @doc """
    Invalid JSON - Unexpected token
  """
  def message(exception), do: "Invalid JSON - unexpected token >>#{exception.token}<<"
end

defmodule JSON.Encoder.Error do
  @moduledoc """
  Thrown when an encoder error happens
  """
  defexception error_info: nil

  @doc """
    Invalid Term
  """
  def message(exception) do
    error_message = "An error occurred while encoding the JSON object"

    if nil != exception.error_info do
      error_message <> " >>#{exception.error_info}<<"
    else
      error_message
    end
  end
end
