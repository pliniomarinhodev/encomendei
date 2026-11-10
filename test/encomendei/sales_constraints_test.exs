defmodule Encomendei.SalesConstraintsTest do
  use Encomendei.DataCase

  alias Encomendei.Repo
  alias Encomendei.Sales
  alias Encomendei.Sales.{Order, OrderItem}
  import Encomendei.CatalogFixtures

  defp order_fixture do
    product = product_fixture(price_cents: 1000)

    {:ok, order} =
      Sales.place_order(%{
        "name" => "Maria Silva",
        "phone" => "19999991234",
        "delivery_at" => DateTime.add(DateTime.utc_now(), 2, :day),
        "items" => [%{"product_id" => product.id, "quantity" => 1}]
      })

    {order, product}
  end

  test "número da encomenda é gerado pelo banco, sequencial e único" do
    {first, _} = order_fixture()
    {second, _} = order_fixture()

    assert is_integer(first.number)
    assert second.number > first.number

    attrs = %{
      customer_id: first.customer_id,
      delivery_at: DateTime.add(DateTime.utc_now(), 1, :day)
    }

    assert {:error, changeset} =
             %Order{number: first.number}
             |> Order.changeset(attrs)
             |> Repo.insert()

    assert %{number: ["has already been taken"]} = errors_on(changeset)
  end

  test "total negativo é rejeitado no changeset e no banco" do
    {order, _} = order_fixture()

    assert %{total_cents: [_]} =
             errors_on(Order.changeset(order, %{total_cents: -1}))

    assert {:error, cs} =
             order
             |> Ecto.Changeset.change(total_cents: -1)
             |> Ecto.Changeset.check_constraint(:total_cents, name: :total_cents_non_negative)
             |> Repo.update()

    assert %{total_cents: ["is invalid"]} = errors_on(cs)
  end

  test "quantidade zero ou negativa é rejeitada no banco" do
    {order, product} = order_fixture()

    assert {:error, cs} =
             %OrderItem{order_id: order.id, product_id: product.id, unit_price_cents: 100}
             |> Ecto.Changeset.change(quantity: 0)
             |> Ecto.Changeset.check_constraint(:quantity, name: :quantity_positive)
             |> Repo.insert()

    assert %{quantity: ["is invalid"]} = errors_on(cs)
  end

  test "status fora da lista é rejeitado" do
    {order, _} = order_fixture()

    assert {:error, _} =
             Repo.query("UPDATE orders SET status = 'enviado' WHERE id = $1", [
               Ecto.UUID.dump!(order.id)
             ])
             |> to_error()
  end

  defp to_error({:error, %Postgrex.Error{postgres: %{code: :check_violation}}}),
    do: {:error, :check}

  defp to_error(other), do: other
end
