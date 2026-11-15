defmodule EncomendeiWeb.ProductImageControllerTest do
  use EncomendeiWeb.ConnCase

  alias Encomendei.Catalog

  @png <<0x89, "PNG\r\n", 0x1A, "\n", 0, 0, 0, 13, "IHDR">>

  test "entrega a foto enviada sem exigir login, com tipo e cache", %{conn: conn} do
    {:ok, product} = Catalog.create_product(%{name: "Bolo", price: "10", image_data: @png})

    conn = get(conn, ~p"/imagens/produtos/#{product.id}")

    assert response(conn, 200) == @png
    assert [type] = get_resp_header(conn, "content-type")
    assert type == "image/png"
    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
    assert [cache] = get_resp_header(conn, "cache-control")
    assert cache =~ "max-age"
  end

  test "404 para produto sem foto enviada, inexistente ou id inválido", %{conn: conn} do
    {:ok, plain} = Catalog.create_product(%{name: "Torta", price: "10"})

    assert conn |> get(~p"/imagens/produtos/#{plain.id}") |> response(404)
    assert conn |> get(~p"/imagens/produtos/#{Ecto.UUID.generate()}") |> response(404)
    assert conn |> get("/imagens/produtos/nao-e-uuid") |> response(404)
  end
end
