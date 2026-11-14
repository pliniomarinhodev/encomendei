defmodule EncomendeiWeb.TrackLiveTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Encomendei.CatalogFixtures
  alias Encomendei.Sales

  setup do
    product = product_fixture()

    {:ok, order} =
      Sales.place_order(%{
        "name" => "Ana",
        "phone" => "(19) 98888-7777",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 2, :day),
        "items" => [%{"product_id" => product.id, "quantity" => 1}]
      })

    %{order: order}
  end

  test "o cliente reencontra o pedido pelo número e telefone", %{conn: conn, order: order} do
    {:ok, lv, _} = live(conn, ~p"/acompanhar")

    lv
    |> form("#track-form", track: %{number: "##{order.number}", phone: "19 98888-7777"})
    |> render_submit()

    assert_redirect(lv, ~p"/pedido/#{order.id}")
  end

  test "telefone errado não revela o pedido", %{conn: conn, order: order} do
    {:ok, lv, _} = live(conn, ~p"/acompanhar")

    html =
      lv
      |> form("#track-form", track: %{number: "#{order.number}", phone: "19911112222"})
      |> render_submit()

    assert html =~ "Não encontramos um pedido"
    refute html =~ "Ana"
  end

  test "número inexistente ou inválido dá a mesma resposta", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/acompanhar")

    for number <- ["99999", "abc", ""] do
      html =
        lv
        |> form("#track-form", track: %{number: number, phone: "19988887777"})
        |> render_submit()

      assert html =~ "Não encontramos um pedido"
    end
  end

  test "a navegação pública leva às duas telas e à área da confeiteira", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/")
    assert has_element?(lv, ~s(nav[aria-label="Principal"] a[href="/acompanhar"]))
    assert has_element?(lv, ~s(nav[aria-label="Principal"] a[aria-current="page"]), "Cardápio")
    assert html =~ ~s(href="/entrar")
  end

  test "o painel tem botão para sair", %{conn: conn} do
    {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    assert has_element?(lv, ~s(a[href="/sair"][data-method="delete"]), "Sair")
  end
end
