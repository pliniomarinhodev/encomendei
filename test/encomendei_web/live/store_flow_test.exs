defmodule EncomendeiWeb.StoreFlowTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Encomendei.CatalogFixtures
  alias Encomendei.Sales

  defp future_local do
    DateTime.utc_now() |> DateTime.add(2, :day) |> DateTime.add(-3 * 3600) |> Calendar.strftime("%Y-%m-%dT%H:%M")
  end

  test "mostra só produtos disponíveis", %{conn: conn} do
    product_fixture(name: "Bolo de Cenoura")
    product_fixture(name: "Bolo Escondido", available: false)

    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Bolo de Cenoura"
    refute html =~ "Bolo Escondido"
  end

  test "cliente monta o carrinho, envia e vê a confirmação", %{conn: conn} do
    product = product_fixture(name: "Bolo de Cenoura", price_cents: 4500)
    {:ok, lv, _} = live(conn, ~p"/")

    render_click(lv, "add", %{"id" => product.id})
    html = render_click(lv, "add", %{"id" => product.id})
    assert html =~ "R$ 90,00"

    lv
    |> form("#checkout-form", checkout: %{name: "Ana", phone: "19988887777", delivery_at: future_local(), notes: ""})
    |> render_submit()

    {path, _flash} = assert_redirect(lv)
    assert path =~ "/pedido/"

    {:ok, _lv, html} = live(conn, path)
    assert html =~ "Pedido recebido"
    assert html =~ "Pendente"
    assert html =~ "R$ 90,00"
  end

  test "carrinho vazio não envia", %{conn: conn} do
    product_fixture()
    {:ok, lv, _} = live(conn, ~p"/")

    html =
      lv
      |> form("#checkout-form", checkout: %{name: "Ana", phone: "19988887777", delivery_at: future_local()})
      |> render_submit()

    assert html =~ "Adicione ao menos um item"
    assert Sales.list_orders() == []
  end

  test "cliente acompanha a mudança de status em tempo real", %{conn: conn} do
    product = product_fixture()
    {:ok, order} = Sales.place_order(%{"name" => "Ana", "phone" => "19988887777", "delivery_at" => DateTime.add(DateTime.utc_now(), 1, :day), "items" => [%{"product_id" => product.id, "quantity" => 1}]})

    {:ok, lv, html} = live(conn, ~p"/pedido/#{order.id}")
    assert html =~ "Pendente"

    {:ok, _} = Sales.update_status(order, :in_production)
    assert render(lv) =~ "Em produção"
  end
end
