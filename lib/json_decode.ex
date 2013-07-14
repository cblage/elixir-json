defprotocol JSON.Decode do
  
  @moduledoc """
  Defines the protocol required for converting Elixir types into JSON and inferring their json types.
  """
  @only [BitString]

  def from_json(item)

end

defimpl JSON.Decode, for: BitString do

  def from_json("[]") do 
    []
  end

end
