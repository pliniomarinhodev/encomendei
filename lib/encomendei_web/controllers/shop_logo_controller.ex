defmodule EncomendeiWeb.ShopLogoController do
  use EncomendeiWeb, :controller

  alias Encomendei.Shop

  @doc "Entrega o logo da loja. O endereço leva `?v=` e por isso pode ficar em cache."
  def show(conn, _params) do
    case Shop.get_logo() do
      {type, data} ->
        conn
        |> put_resp_content_type(type, nil)
        |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
        |> put_resp_header("x-content-type-options", "nosniff")
        |> put_resp_header("content-security-policy", "default-src 'none'")
        |> send_resp(200, data)

      nil ->
        send_resp(conn, 404, "")
    end
  end
end
