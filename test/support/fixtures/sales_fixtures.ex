defmodule Encomendei.SalesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Encomendei.Sales` context.
  """

  @doc """
  Generate a customer.
  """
  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        name: "some name",
        phone: "some phone"
      })
      |> Encomendei.Sales.create_customer()

    customer
  end

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        delivery_at: ~U[2026-11-09 14:17:00Z],
        notes: "some notes",
        status: "some status",
        total_cents: 42
      })
      |> Encomendei.Sales.create_order()

    order
  end
end
