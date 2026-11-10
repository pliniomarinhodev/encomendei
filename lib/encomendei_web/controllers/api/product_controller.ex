defmodule EncomendeiWeb.API.ProductController do
  use EncomendeiWeb, :controller
  alias Encomendei.Catalog
  alias EncomendeiWeb.API.JSON, as: J

  def index(conn, _params) do
    products = Catalog.list_products() |> Enum.filter(& &1.available)
    json(conn, %{data: Enum.map(products, &J.product/1)})
  end
end
