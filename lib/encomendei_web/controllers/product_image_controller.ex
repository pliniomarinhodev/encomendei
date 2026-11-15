defmodule EncomendeiWeb.ProductImageController do
  use EncomendeiWeb, :controller

  alias Encomendei.Catalog

  @doc "Entrega a foto enviada de um produto. O endereço leva `?v=` e por isso pode ficar em cache."
  def show(conn, %{"id" => id}) do
    with {:ok, uuid} <- Ecto.UUID.cast(id),
         {type, data} <- Catalog.get_product_image(uuid) do
      conn
      |> put_resp_content_type(type, nil)
      |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> put_resp_header("x-content-type-options", "nosniff")
      |> put_resp_header("content-security-policy", "default-src 'none'")
      |> send_resp(200, data)
    else
      _not_found -> send_resp(conn, 404, "")
    end
  end
end
