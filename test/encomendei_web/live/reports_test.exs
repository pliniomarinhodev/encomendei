defmodule EncomendeiWeb.ReportsTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Encomendei.CatalogFixtures
  alias Encomendei.Sales

  test "exige senha", %{conn: conn} do
    assert get(conn, ~p"/admin/relatorios").status == 401
    assert get(conn, ~p"/admin/relatorios/pedidos.csv").status == 401
  end

  test "mostra indicadores e atualiza com novo pedido", %{conn: conn} do
    bolo = product_fixture(name: "Bolo de Limão", price_cents: 4800)
    {:ok, lv, html} = conn |> admin_conn() |> live(~p"/admin/relatorios")
    assert html =~ "Ainda não há vendas"

    {:ok, _} =
      Sales.place_order(%{
        "name" => "Ana",
        "phone" => "19988887777",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 1, :day),
        "items" => [%{"product_id" => bolo.id, "quantity" => 2}]
      })

    html = render(lv)
    assert html =~ "R$ 96,00"
    assert html =~ "Bolo de Limão"
  end

  test "CSV traz os itens e neutraliza fórmulas", %{conn: conn} do
    bolo = product_fixture(name: "=HYPERLINK(\"x\")", price_cents: 1050)

    {:ok, _} =
      Sales.place_order(%{
        "name" => "+Ana",
        "phone" => "19988887777",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 1, :day),
        "items" => [%{"product_id" => bolo.id, "quantity" => 3}]
      })

    conn = conn |> admin_conn() |> get(~p"/admin/relatorios/pedidos.csv")
    assert response_content_type(conn, :csv) =~ "text/csv"

    assert get_resp_header(conn, "content-disposition") == [
             ~S|attachment; filename="pedidos.csv"|
           ]

    body = response(conn, 200)
    assert body =~ ~S|"pedido","entrega","status"|
    assert body =~ ~S|"'+Ana"|
    assert body =~ ~S|"'=HYPERLINK(""x"")"|
    assert body =~ ~S|"10.50"|
  end
end
