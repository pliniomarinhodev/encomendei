defmodule EncomendeiWeb.APITest do
  use EncomendeiWeb.ConnCase

  import Encomendei.CatalogFixtures

  defp future, do: DateTime.utc_now() |> DateTime.add(2, :day) |> DateTime.to_iso8601()

  defp order_params(product, extra \\ %{}) do
    Map.merge(
      %{
        "name" => "Ana",
        "phone" => "19988887777",
        "delivery_at" => future(),
        "items" => [%{"product_id" => product.id, "quantity" => 2}]
      },
      extra
    )
  end

  test "GET /api/products lista só os disponíveis", %{conn: conn} do
    product_fixture(name: "Visível", price_cents: 1000)
    product_fixture(name: "Oculto", available: false)

    assert %{"data" => [%{"name" => "Visível", "price_cents" => 1000}]} =
             conn |> get(~p"/api/products") |> json_response(200)
  end

  describe "POST /api/orders" do
    test "cria pedido e responde 201", %{conn: conn} do
      product = product_fixture(price_cents: 2500)
      resp = conn |> post(~p"/api/orders", order_params(product)) |> json_response(201)

      assert %{"data" => %{"id" => id, "status" => "pending", "total_cents" => 5000}} = resp

      assert %{"data" => %{"id" => ^id}} =
               conn |> get(~p"/api/orders/#{id}") |> json_response(200)
    end

    test "sem delivery_at o pedido é para o mais rápido possível", %{conn: conn} do
      product = product_fixture()
      params = product |> order_params() |> Map.delete("delivery_at")

      resp = conn |> post(~p"/api/orders", params) |> json_response(201)
      assert %{"data" => %{"scheduled" => false}} = resp
    end

    test "aceita retirada e mensagem do bolo", %{conn: conn} do
      product = product_fixture()

      params =
        order_params(product, %{"fulfillment" => "pickup", "cake_message" => "Parabéns!"})

      resp = conn |> post(~p"/api/orders", params) |> json_response(201)

      assert %{"data" => %{"fulfillment" => "pickup", "cake_message" => "Parabéns!"}} = resp
    end

    test "422 com data inválida", %{conn: conn} do
      product = product_fixture()

      resp =
        conn
        |> post(~p"/api/orders", order_params(product, %{"delivery_at" => "amanhã"}))
        |> json_response(422)

      assert resp["errors"]["delivery_at"]
    end

    test "422 com data no passado", %{conn: conn} do
      product = product_fixture()
      past = DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.to_iso8601()

      resp =
        conn
        |> post(~p"/api/orders", order_params(product, %{"delivery_at" => past}))
        |> json_response(422)

      assert resp["errors"]["delivery_at"] == ["deve ser uma data futura"]
    end

    test "422 com carrinho vazio e com produto indisponível", %{conn: conn} do
      product = product_fixture()

      assert %{"errors" => %{"items" => _}} =
               conn
               |> post(~p"/api/orders", order_params(product, %{"items" => []}))
               |> json_response(422)

      hidden = product_fixture(available: false)

      assert %{"errors" => %{"items" => _}} =
               conn |> post(~p"/api/orders", order_params(hidden)) |> json_response(422)
    end

    test "422 com id de produto malformado (antes quebrava com 500)", %{conn: conn} do
      product = product_fixture()
      params = order_params(product, %{"items" => [%{"product_id" => "abc", "quantity" => 1}]})

      assert %{"errors" => %{"items" => _}} =
               conn |> post(~p"/api/orders", params) |> json_response(422)
    end

    test "422 com quantidade acima do limite", %{conn: conn} do
      product = product_fixture()

      params =
        order_params(product, %{"items" => [%{"product_id" => product.id, "quantity" => 100}]})

      assert %{"errors" => %{"quantity" => _}} =
               conn |> post(~p"/api/orders", params) |> json_response(422)
    end

    test "422 com telefone inválido", %{conn: conn} do
      product = product_fixture()

      resp =
        conn
        |> post(~p"/api/orders", order_params(product, %{"phone" => "12"}))
        |> json_response(422)

      assert resp["errors"]["phone"]
    end

    test "ignora preço enviado pelo cliente", %{conn: conn} do
      product = product_fixture(price_cents: 3000)

      params =
        order_params(product, %{
          "items" => [%{"product_id" => product.id, "quantity" => 1, "unit_price_cents" => 1}]
        })

      assert %{"data" => %{"total_cents" => 3000}} =
               conn |> post(~p"/api/orders", params) |> json_response(201)
    end
  end

  test "GET /api/orders/:id com id inexistente ou inválido dá 404", %{conn: conn} do
    assert conn |> get(~p"/api/orders/#{Ecto.UUID.generate()}") |> json_response(404)
    assert conn |> get(~p"/api/orders/abc") |> json_response(404)
  end

  describe "rotas administrativas" do
    setup %{conn: conn} do
      product = product_fixture()

      %{"data" => %{"id" => id}} =
        conn |> post(~p"/api/orders", order_params(product)) |> json_response(201)

      %{id: id}
    end

    test "exigem senha", %{conn: conn, id: id} do
      assert conn |> get(~p"/api/admin/orders") |> response(401)

      assert conn
             |> patch(~p"/api/admin/orders/#{id}/status", %{"status" => "in_production"})
             |> response(401)
    end

    test "lista e filtra por status", %{conn: conn} do
      conn = api_admin_conn(conn)
      assert %{"data" => [_]} = conn |> get(~p"/api/admin/orders") |> json_response(200)

      assert %{"data" => []} =
               conn |> get(~p"/api/admin/orders?status=delivered") |> json_response(200)
    end

    test "muda status respeitando o fluxo", %{conn: conn, id: id} do
      conn = api_admin_conn(conn)

      assert %{"data" => %{"status" => "in_production"}} =
               conn
               |> patch(~p"/api/admin/orders/#{id}/status", %{"status" => "in_production"})
               |> json_response(200)

      assert %{"errors" => %{"status" => _}} =
               conn
               |> patch(~p"/api/admin/orders/#{id}/status", %{"status" => "pending"})
               |> json_response(422)

      assert %{"errors" => %{"status" => _}} =
               conn
               |> patch(~p"/api/admin/orders/#{id}/status", %{"status" => "xyz"})
               |> json_response(422)
    end
  end
end
