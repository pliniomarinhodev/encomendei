defmodule Encomendei.ReportsTest do
  use Encomendei.DataCase

  alias Encomendei.{Reports, Sales}
  import Encomendei.CatalogFixtures

  defp order!(product, qty, phone \\ "19988887777") do
    {:ok, order} =
      Sales.place_order(%{
        "name" => "Ana",
        "phone" => phone,
        "delivery_at" => DateTime.add(DateTime.utc_now(), 2, :day),
        "items" => [%{"product_id" => product.id, "quantity" => qty}]
      })

    order
  end

  test "resumo vazio não divide por zero" do
    assert %{orders: 0, revenue_cents: 0, average_ticket_cents: 0} = Reports.summary()
  end

  test "resumo soma faturamento e ignora cancelados" do
    bolo = product_fixture(name: "Bolo", price_cents: 5000)
    order!(bolo, 2)
    order!(bolo, 1)
    cancelado = order!(bolo, 10)
    {:ok, _} = Sales.update_status(cancelado, :canceled)

    s = Reports.summary()
    assert s.orders == 2
    assert s.revenue_cents == 15_000
    assert s.average_ticket_cents == 7_500
    assert s.by_status.pending == 2
    assert s.by_status.canceled == 1
  end

  test "ranking ordena por quantidade e ignora cancelados" do
    bolo = product_fixture(name: "Bolo", price_cents: 5000)
    torta = product_fixture(name: "Torta", price_cents: 3000)
    order!(bolo, 1)
    order!(torta, 4)
    {:ok, _} = Sales.update_status(order!(bolo, 50), :canceled)

    assert [%{name: "Torta", quantity: 4, revenue_cents: 12_000}, %{name: "Bolo", quantity: 1}] =
             Reports.top_products()
  end

  test "agrupa por semana" do
    bolo = product_fixture(price_cents: 1000)
    order!(bolo, 1)
    order!(bolo, 2)
    assert [%{orders: 2, revenue_cents: 3000}] = Reports.weekly()
  end
end
