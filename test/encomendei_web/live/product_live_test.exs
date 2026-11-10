defmodule EncomendeiWeb.ProductLiveTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest
  import Encomendei.CatalogFixtures

  alias Encomendei.{Catalog, Sales}

  setup %{conn: conn}, do: {:ok, conn: admin_conn(conn)}

  describe "Index" do
    test "lista produtos com preço em reais e situação", %{conn: conn} do
      product_fixture(name: "Bolo de Limão", price_cents: 4800)
      product_fixture(name: "Torta Oculta", price_cents: 3000, available: false)

      {:ok, view, html} = live(conn, ~p"/admin/produtos")

      assert has_element?(view, "#products")
      assert html =~ "Bolo de Limão"
      assert html =~ "R$ 48,00"
      assert html =~ "Indisponível"
    end

    test "marca a aba Produtos como ativa", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/produtos")
      assert has_element?(view, ~s(nav[aria-label="Painel"] a[aria-current="page"]), "Produtos")
    end

    test "exclui produto sem vendas", %{conn: conn} do
      product = product_fixture()
      {:ok, view, _html} = live(conn, ~p"/admin/produtos")

      view |> element("#products-#{product.id} a", "Excluir") |> render_click()

      refute has_element?(view, "#products-#{product.id}")
      assert Catalog.list_products() == []
    end

    test "não exclui produto já vendido e orienta a marcar como indisponível", %{conn: conn} do
      product = product_fixture(name: "Bolo Vendido")

      {:ok, _order} =
        Sales.place_order(%{
          "name" => "Ana",
          "phone" => "19988887777",
          "delivery_at" => DateTime.add(DateTime.utc_now(), 1, :day),
          "items" => [%{"product_id" => product.id, "quantity" => 1}]
        })

      {:ok, view, _html} = live(conn, ~p"/admin/produtos")
      html = view |> element("#products-#{product.id} a", "Excluir") |> render_click()

      assert html =~ "já foi vendido"
      assert has_element?(view, "#products-#{product.id}")
      assert [%{name: "Bolo Vendido"}] = Catalog.list_products()
    end
  end

  describe "Form" do
    test "cadastra produto informando o preço em reais", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/produtos/new")

      {:ok, _view, html} =
        view
        |> form("#product-form",
          product: %{name: "Bolo de Fubá", price: "45,50", available: true}
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/produtos")

      assert html =~ "Produto salvo"

      assert [%{name: "Bolo de Fubá", price_cents: 4550, available: true}] =
               Catalog.list_products()
    end

    test "mostra erro de preço inválido e de campos obrigatórios", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/produtos/new")

      html =
        view
        |> form("#product-form", product: %{name: "", price: "abc"})
        |> render_change()

      assert html =~ "informe um valor como 45,00"
      assert html =~ "can&#39;t be blank" or html =~ "não pode ficar em branco"
      assert Catalog.list_products() == []
    end

    test "edição já traz o preço atual em reais e salva a alteração", %{conn: conn} do
      product = product_fixture(price_cents: 4800)
      {:ok, view, html} = live(conn, ~p"/admin/produtos/#{product}/edit")
      assert html =~ ~s(value="48,00")

      {:ok, _view, _html} =
        view
        |> form("#product-form", product: %{price: "52", available: false})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/produtos")

      assert %{price_cents: 5200, available: false} = Catalog.get_product!(product.id)
    end
  end

  describe "Show" do
    test "mostra os dados do produto", %{conn: conn} do
      product = product_fixture(name: "Bolo de Cenoura", price_cents: 5500)
      {:ok, _view, html} = live(conn, ~p"/admin/produtos/#{product}")

      assert html =~ "Bolo de Cenoura"
      assert html =~ "R$ 55,00"
      assert html =~ "Disponível"
    end
  end
end
