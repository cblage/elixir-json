defmodule JSON.Dynamo.Filter do
  defmodule FilterResultObject do
    def run(nil), do: nil

    def run(result_object), do: JSON.encode!(result_object)
  end

  defmodule ProcessFilteredResponse do
    def run(nil, conn), do: conn

    def run(filtered_response, conn) do
      conn
        .resp_content_type("application/json")
        .resp_body(filtered_response)
    end
  end


  def finalize(conn) do
    FilterResultObject.run(conn.private[:result_object])
      |> ProcessFilteredResponse.run(conn)
  end
end
