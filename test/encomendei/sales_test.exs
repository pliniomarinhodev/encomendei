defmodule Encomendei.SalesTest do
  use Encomendei.DataCase

  alias Encomendei.Sales
  import Encomendei.CatalogFixtures

  defp valid_attrs(product, extra \\ %{}) do
    Map.merge(
      %{
        "name" => "Maria Silva",
        "phone" => "(19) 99999-1234",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 2, :day),
        "notes" => "Sem nozes",
        "items" => [%{"product_id" => product.id, "quantity" => "2"}]
      },
      extra
    )
  end

  describe "place_order/1" do
    test "cria pedido, cliente e itens e calcula o total no servidor" do
      product = product_fixture(price_cents: 5000)

      # Tentativa de forjar o preço é ignorada
      attrs =
        valid_attrs(product, %{
          "items" => [%{"product_id" => product.id, "quantity" => 2, "unit_price_cents" => 1}]
        })

      assert {:ok, order} = Sales.place_order(attrs)
      assert order.total_cents == 10_000
      assert order.status == :pending
      assert order.customer.phone == "19999991234"
      assert [%{quantity: 2, unit_price_cents: 5000}] = order.items
    end

    test "reaproveita o cliente pelo telefone" do
      product = product_fixture()
      {:ok, a} = Sales.place_order(valid_attrs(product))
      {:ok, b} = Sales.place_order(valid_attrs(product, %{"name" => "Maria S."}))
      assert a.customer_id == b.customer_id
      assert length(Sales.list_customers()) == 1
    end

    test "rejeita carrinho vazio" do
      product = product_fixture()
      assert {:error, :empty_cart} = Sales.place_order(valid_attrs(product, %{"items" => []}))
    end

    test "rejeita produto indisponível" do
      product = product_fixture(available: false)
      assert {:error, :unavailable_product} = Sales.place_order(valid_attrs(product))
    end

    test "rejeita data de entrega no passado" do
      product = product_fixture()
      past = DateTime.add(DateTime.utc_now(), -1, :day)

      assert {:error, %Ecto.Changeset{} = cs} =
               Sales.place_order(valid_attrs(product, %{"delivery_at" => past}))

      assert "deve ser uma data futura" in errors_on(cs).delivery_at
    end

    test "rejeita cliente sem telefone válido" do
      product = product_fixture()

      assert {:error, %Ecto.Changeset{} = cs} =
               Sales.place_order(valid_attrs(product, %{"phone" => "123"}))

      assert errors_on(cs).phone != []
    end

    test "não grava nada quando falha (transação)" do
      product = product_fixture()
      past = DateTime.add(DateTime.utc_now(), -1, :day)
      Sales.place_order(valid_attrs(product, %{"delivery_at" => past}))
      assert Sales.list_orders() == []
    end
  end

  describe "update_status/2" do
    setup do
      {:ok, order} = Sales.place_order(valid_attrs(product_fixture()))
      %{order: order}
    end

    test "segue o fluxo pendente → em produção → entregue", %{order: order} do
      assert {:ok, order} = Sales.update_status(order, :in_production)
      assert {:ok, order} = Sales.update_status(order, :delivered)
      assert order.status == :delivered
    end

    test "não permite pular etapa nem sair de estado final", %{order: order} do
      assert {:error, :invalid_transition} = Sales.update_status(order, :delivered)
      {:ok, order} = Sales.update_status(order, :canceled)
      assert {:error, :invalid_transition} = Sales.update_status(order, :in_production)
    end

    test "avisa quem está ouvindo (painel em tempo real)", %{order: order} do
      Sales.subscribe()
      {:ok, _} = Sales.update_status(order, :in_production)
      id = order.id
      assert_receive {:order_updated, ^id}
    end
  end

  test "list_orders/1 filtra por status e ordena pela entrega" do
    product = product_fixture()

    {:ok, late} =
      Sales.place_order(
        valid_attrs(product, %{"delivery_at" => DateTime.add(DateTime.utc_now(), 5, :day)})
      )

    {:ok, soon} =
      Sales.place_order(
        valid_attrs(product, %{"delivery_at" => DateTime.add(DateTime.utc_now(), 1, :day)})
      )

    {:ok, _} = Sales.update_status(late, :in_production)

    assert [first, second] = Sales.list_orders()
    assert first.id == soon.id and second.id == late.id
    assert [%{id: id}] = Sales.list_orders(status: :in_production)
    assert id == late.id
  end
end
