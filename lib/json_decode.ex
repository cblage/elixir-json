defmodule JSON.Decode do
  defexception UnexpectedTokenError, token: nil do
    def message(exception) do
      "Invalid JSON - unexpected token >>#{exception.token}<<"
    end
  end
  
  defexception UnexpectedEndOfBufferError, message: "Invalid JSON - unexpected end of buffer"
  
  def from_json("[]") do 
    []
  end

  def from_json("{}") do 
    []
  end

  def from_json(bitstring) when is_bitstring(bitstring) do
    _accept_root_token(bitstring)
  end

  #Accepts anything considered a root token (object or array for now)
  defp _accept_root_token(bitstring) do
    {root_token, remaining_bitstring} = _consume_whitespace(bitstring) |> _process_root_token
                                          
    #remaining_bitstring should be empty due to being in the root context otherwise this is invalid json
    if ("" !== _consume_whitespace(remaining_bitstring)) do 
      raise UnexpectedTokenError, token: remaining_bitstring
    end

    root_token
  end

   defp _process_root_token(<< "{" , tail :: binary >>) do
    _accept_object(tail)    
  end

  defp _process_root_token(<< "[" , tail :: binary >>) do
    _accept_list(tail)
  end

  defp _process_root_token(token) when is_bitstring(token) do
    raise UnexpectedTokenError, token: token
  end

  defp _accept_object(bitstring) when is_bitstring(bitstring) do 
    raise "not implemented"
  end
  
  defp _accept_list(bitstring) when is_bitstring(bitstring) do 
    raise "not implemented"
  end


  # consume whitespace, 32 = ascii space
  defp _consume_whitespace(<< token :: utf8, tail :: binary>>) when token in [?\t, ?\r, ?\n, 32] do
    _consume_whitespace(tail)
  end

  defp _consume_whitespace(bitstring) when is_bitstring(bitstring) do
    bitstring
  end

  defp _accept_string_token(<< "\"" , tail :: binary >>) do
    _accept_string(tail, "")
  end

  defp _accept_string_token(<< token :: utf8, _ >>) do
    raise UnexpectedTokenError, token: token
  end

  #Stop condition for proper end of string
  defp _accept_string("\"", accumulator) do
    accumulator
  end
  
  defp _accept_string(<<>>, _) do
    raise UnexpectedEndOfBufferError
  end

end

