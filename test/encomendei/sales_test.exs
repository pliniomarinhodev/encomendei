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

  describe "place_order/1 com dados inválidos nos itens" do
    test "id de produto malformado vira :unavailable_product em vez de exceção" do
      product = product_fixture()

      attrs =
        valid_attrs(product, %{"items" => [%{"product_id" => "não-é-uuid", "quantity" => 1}]})

      assert {:error, :unavailable_product} = Sales.place_order(attrs)
    end

    test "quantidade acima do limite devolve changeset e desfaz tudo" do
      product = product_fixture()

      attrs =
        valid_attrs(product, %{"items" => [%{"product_id" => product.id, "quantity" => 100}]})

      assert {:error, %Ecto.Changeset{} = cs} = Sales.place_order(attrs)
      assert errors_on(cs).quantity != []
      assert Sales.list_orders() == []
      assert Sales.list_customers() == []
    end

    test "linhas com quantidade zero são ignoradas" do
      product = product_fixture(price_cents: 1000)
      other = product_fixture(price_cents: 500)

      items = [
        %{"product_id" => product.id, "quantity" => 0},
        %{"product_id" => other.id, "quantity" => "2"}
      ]

      assert {:ok, order} = Sales.place_order(valid_attrs(product, %{"items" => items}))
      assert order.total_cents == 1000
      assert [%{product_id: id}] = order.items
      assert id == other.id
    end

    test "congela o preço do item mesmo se o catálogo mudar depois" do
      product = product_fixture(price_cents: 4000)
      {:ok, order} = Sales.place_order(valid_attrs(product))
      {:ok, _} = Encomendei.Catalog.update_product(product, %{price_cents: 9999})

      assert Sales.get_order!(order.id).total_cents == 8000
      assert [%{unit_price_cents: 4000}] = Sales.get_order!(order.id).items
    end
  end

  describe "production_queue/0" do
    defp place!(product, days, phone) do
      {:ok, order} =
        Sales.place_order(
          valid_attrs(product, %{
            "phone" => phone,
            "delivery_at" => DateTime.add(DateTime.utc_now(), days, :day)
          })
        )

      order
    end

    test "agrupa por status e ordena as abertas pela entrega mais próxima" do
      product = product_fixture()
      late = place!(product, 5, "19900000001")
      soon = place!(product, 1, "19900000002")
      producing = place!(product, 2, "19900000003")
      {:ok, _} = Sales.update_status(producing, :in_production)

      assert %{pending: [first, second], in_production: [%{id: id}], delivered: []} =
               Sales.production_queue()

      assert [first.id, second.id] == [soon.id, late.id]
      assert id == producing.id
    end

    test "canceladas ficam fora da fila" do
      product = product_fixture()
      order = place!(product, 1, "19900000004")
      {:ok, _} = Sales.update_status(order, :canceled)
      assert %{pending: [], in_production: [], delivered: []} = Sales.production_queue()
    end

    test "entregues mostram só as 10 mais recentes" do
      product = product_fixture()

      for n <- 1..12 do
        order = place!(product, 1, "1990000#{String.pad_leading("#{n}", 4, "0")}")
        {:ok, order} = Sales.update_status(order, :in_production)
        {:ok, _} = Sales.update_status(order, :delivered)
      end

      assert length(Sales.production_queue().delivered) == 10
    end
  end

  describe "fetch_order/1" do
    test "devolve {:ok, order} com cliente e itens carregados" do
      {:ok, order} = Sales.place_order(valid_attrs(product_fixture()))

      assert {:ok, %{id: id, customer: %{name: "Maria Silva"}, items: [_]}} =
               Sales.fetch_order(order.id)

      assert id == order.id
    end

    test "id inexistente ou malformado devolve {:error, :not_found}" do
      assert {:error, :not_found} = Sales.fetch_order(Ecto.UUID.generate())
      assert {:error, :not_found} = Sales.fetch_order("abc")
      assert {:error, :not_found} = Sales.fetch_order(nil)
    end
  end

  describe "next_statuses/1" do
    test "reflete o fluxo de produção" do
      assert Sales.next_statuses(:pending) == [:in_production, :canceled]
      assert Sales.next_statuses(:in_production) == [:delivered, :canceled]
      assert Sales.next_statuses(:delivered) == []
      assert Sales.next_statuses(:canceled) == []
    end
  end

  test "Order.parse_status/1 aceita só nomes de status conhecidos" do
    assert {:ok, :in_production} = Encomendei.Sales.Order.parse_status("in_production")
    assert {:error, :invalid_status} = Encomendei.Sales.Order.parse_status("xyz")
    assert {:error, :invalid_status} = Encomendei.Sales.Order.parse_status(nil)
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

  describe "entrega o mais rápido possível" do
    test "sem data, o pedido fica não agendado com a hora do pedido", %{} do
      product = product_fixture()
      before = DateTime.utc_now() |> DateTime.add(-2)

      {:ok, order} = Sales.place_order(Map.delete(valid_attrs(product), "delivery_at"))

      assert order.scheduled == false
      assert DateTime.compare(order.delivery_at, before) == :gt
      assert DateTime.compare(order.delivery_at, DateTime.add(DateTime.utc_now(), 2)) == :lt
    end

    test "data em branco também vale como o mais rápido possível" do
      product = product_fixture()
      {:ok, order} = Sales.place_order(valid_attrs(product, %{"delivery_at" => ""}))
      assert order.scheduled == false
    end

    test "com data futura, o pedido é agendado" do
      product = product_fixture()
      {:ok, order} = Sales.place_order(valid_attrs(product))
      assert order.scheduled == true
    end

    test "data inválida continua sendo erro, não vira o mais rápido possível" do
      product = product_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Sales.place_order(valid_attrs(product, %{"delivery_at" => "ontem"}))
    end
  end

  describe "retirada e mensagem do bolo" do
    test "sem forma de recebimento, vale entrega e sem mensagem" do
      product = product_fixture()
      {:ok, order} = Sales.place_order(valid_attrs(product))
      assert order.fulfillment == :delivery
      assert order.cake_message == nil
    end

    test "aceita retirada e guarda a mensagem do bolo" do
      product = product_fixture()

      {:ok, order} =
        Sales.place_order(
          valid_attrs(product, %{"fulfillment" => "pickup", "cake_message" => "Parabéns, João!"})
        )

      assert order.fulfillment == :pickup
      assert order.cake_message == "Parabéns, João!"
    end

    test "recusa forma de recebimento desconhecida e mensagem longa demais" do
      product = product_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Sales.place_order(valid_attrs(product, %{"fulfillment" => "drone"}))

      assert {:error, %Ecto.Changeset{}} =
               Sales.place_order(
                 valid_attrs(product, %{"cake_message" => String.duplicate("a", 121)})
               )
    end
  end
end
