defmodule EncomendeiWeb.Admin.OrdersLiveTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Encomendei.CatalogFixtures
  import Ecto.Query
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
    conn =
      put_req_header(conn, "authorization", Plug.BasicAuth.encode_basic_auth("admin", "errada"))

    assert get(conn, ~p"/admin/pedidos").status == 401
  end

  test "lista pedidos e avança o status", %{conn: conn, order: order} do
    {:ok, lv, html} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    assert html =~ "Ana"
    assert html =~ "##{order.number}"
    assert html =~ "wa.me/55"
    assert html =~ URI.encode("pedido #{"##{order.number}"}", &URI.char_unreserved?/1)

    lv |> element("#order-#{order.id} button", "Iniciar produção") |> render_click()
    assert Sales.get_order!(order.id).status == :in_production
  end

  test "pedido novo aparece sem recarregar", %{conn: conn, order: _} do
    {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    product = product_fixture(name: "Torta")

    {:ok, _} =
      Sales.place_order(%{
        "name" => "Beto",
        "phone" => "19977776666",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 3, :day),
        "items" => [%{"product_id" => product.id, "quantity" => 1}]
      })

    html = render(lv)
    assert html =~ "Beto"
    assert has_element?(lv, "#flash-info", "Novo pedido")
    assert html =~ "row-highlight"
  end

  test "mudar o status confirma na tela e destaca a linha", %{conn: conn, order: order} do
    {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")

    lv |> element("#order-#{order.id} button", "Iniciar produção") |> render_click()

    assert has_element?(lv, "#flash-info", "em produção")
    assert has_element?(lv, "#order-#{order.id}.row-highlight")
  end

  describe "busca e filtro" do
    defp place!(name, phone, days) do
      product = product_fixture()

      {:ok, order} =
        Sales.place_order(%{
          "name" => name,
          "phone" => phone,
          "delivery_at" => DateTime.add(DateTime.utc_now(), days, :day),
          "items" => [%{"product_id" => product.id, "quantity" => 1}]
        })

      order
    end

    test "busca por nome sem diferenciar acento ou caixa", %{conn: conn} do
      joao = place!("João Pereira", "19911112222", 3)
      {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")

      lv |> form("#order-filter", %{q: "joao", scope: "all"}) |> render_change()

      assert has_element?(lv, "#order-#{joao.id}")
      refute has_element?(lv, "#orders-pending", "Ana")
    end

    test "busca por número e por telefone", %{conn: conn, order: ana} do
      beto = place!("Beto", "19977776666", 3)
      {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")

      lv |> form("#order-filter", %{q: "##{beto.number}", scope: "all"}) |> render_change()
      assert has_element?(lv, "#order-#{beto.id}")
      refute has_element?(lv, "#order-#{ana.id}")

      lv |> form("#order-filter", %{q: "88887777", scope: "all"}) |> render_change()
      assert has_element?(lv, "#order-#{ana.id}")
      refute has_element?(lv, "#order-#{beto.id}")
    end

    test "filtra por entrega e mantém o total em aberto", %{conn: conn, order: ana} do
      atrasada = place!("Atrasada", "19955554444", 3)

      Encomendei.Repo.update_all(
        from(o in Encomendei.Sales.Order, where: o.id == ^atrasada.id),
        set: [
          delivery_at: DateTime.add(DateTime.utc_now(), -2, :hour) |> DateTime.truncate(:second)
        ]
      )

      {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")
      lv |> form("#order-filter", %{q: "", scope: "overdue"}) |> render_change()

      assert has_element?(lv, "#order-#{atrasada.id}")
      refute has_element?(lv, "#order-#{ana.id}")
      assert render(lv) =~ "2 em aberto"
    end
  end

  test "pedidos cancelados ficam visíveis em um grupo próprio", %{conn: conn, order: order} do
    {:ok, lv, _} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    refute has_element?(lv, "#group-canceled")

    lv |> element("#order-#{order.id} button", "Cancelar") |> render_click()

    assert has_element?(lv, "#group-canceled #order-#{order.id}")
    refute has_element?(lv, "#group-pending #order-#{order.id}")
  end

  test "agrupa por status com contagem e total", %{conn: conn, order: order} do
    {:ok, view, _html} = conn |> admin_conn() |> live(~p"/admin/pedidos")

    assert has_element?(view, "#group-pending #order-#{order.id}")
    assert has_element?(view, "#group-in_production", "Nenhum pedido")
    assert has_element?(view, "#group-delivered", "Nenhum pedido")

    view |> element("#order-#{order.id} button", "Iniciar produção") |> render_click()

    assert has_element?(view, "#group-in_production #order-#{order.id}")
    refute has_element?(view, "#group-pending #order-#{order.id}")
  end

  test "cancelar pede confirmação no navegador", %{conn: conn, order: order} do
    {:ok, view, _html} = conn |> admin_conn() |> live(~p"/admin/pedidos")

    assert has_element?(
             view,
             ~s(#order-#{order.id} button[data-confirm="Cancelar este pedido?"]),
             "Cancelar"
           )
  end

  test "mudança de status inválida mostra aviso e não altera o pedido", %{
    conn: conn,
    order: order
  } do
    {:ok, view, _html} = conn |> admin_conn() |> live(~p"/admin/pedidos")
    html = render_click(view, "status", %{"id" => order.id, "to" => "delivered"})

    assert html =~ "não é permitida"
    assert Sales.get_order!(order.id).status == :pending
    assert render_click(view, "status", %{"id" => order.id, "to" => "xyz"}) =~ "não é permitida"
    assert render_click(view, "status", %{"id" => "abc", "to" => "pending"}) =~ "não é permitida"
  end
end
