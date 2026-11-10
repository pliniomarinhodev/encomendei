defmodule EncomendeiWeb.Admin.OrdersLiveTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Encomendei.CatalogFixtures
  alias Encomendei.Sales

  setup do
    product = product_fixture()

    {:ok, order} =
      Sales.place_order(%{
        "name" => "Ana",
        "phone" => "19988887777",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 1, :day),
        "items" => [%{"product_id" => product.id, "quantity" => 1}]
      })

    %{order: order}
  end

  test "exige senha", %{conn: conn} do
    assert get(conn, ~p"/admin/pedidos").status == 401
    assert get(conn, ~p"/admin/produtos").status == 401
  end

  test "rejeita senha errada", %{conn: conn} do
    conn = put_req_header(conn, "authorization", Plug.BasicAuth.encode_basic_auth("admin", "errada"))
    assert get(conn, ~p"/admin/pedidos").status == 401
  end

  test "lista pedidos e avança o status", %{conn: conn, order: order} do
    {:ok, lv, html} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    assert html =~ "Ana"

    lv |> element("#order-#{order.id} button", "Mover para Em produção") |> render_click()
    assert Sales.get_order!(order.id).status == :in_production
  end

  test "pedido novo aparece sem recarregar", %{conn: conn, order: _} do
    {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    product = product_fixture(name: "Torta")

    {:ok, _} =
      Sales.place_order(%{"name" => "Beto", "phone" => "19977776666", "delivery_at" => DateTime.add(DateTime.utc_now(), 3, :day), "items" => [%{"product_id" => product.id, "quantity" => 1}]})

    assert render(lv) =~ "Beto"
  end
end
