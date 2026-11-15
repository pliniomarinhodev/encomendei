defmodule EncomendeiWeb.ShopLogoControllerTest do
  use EncomendeiWeb.ConnCase

  alias Encomendei.Shop

  @png <<0x89, "PNG\r\n", 0x1A, "\n", 0, 0, 0, 13, "IHDR">>

  test "entrega o logo sem exigir login", %{conn: conn} do
    {:ok, _} = Shop.update_settings(%{name: "Loja", logo_data: @png})

    conn = get(conn, ~p"/imagens/logo")

    assert response(conn, 200) == @png
    assert get_resp_header(conn, "content-type") == ["image/png"]
    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
  end

  test "404 quando a loja não tem logo", %{conn: conn} do
    assert conn |> get(~p"/imagens/logo") |> response(404)
  end
end
