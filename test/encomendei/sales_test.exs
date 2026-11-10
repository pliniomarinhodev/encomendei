defmodule Encomendei.SalesTest do
  use Encomendei.DataCase

  alias Encomendei.Sales

  describe "customers" do
    alias Encomendei.Sales.Customer

    import Encomendei.SalesFixtures

    @invalid_attrs %{name: nil, phone: nil}

    test "list_customers/0 returns all customers" do
      customer = customer_fixture()
      assert Sales.list_customers() == [customer]
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      assert Sales.get_customer!(customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{name: "some name", phone: "some phone"}

      assert {:ok, %Customer{} = customer} = Sales.create_customer(valid_attrs)
      assert customer.name == "some name"
      assert customer.phone == "some phone"
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sales.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = customer_fixture()
      update_attrs = %{name: "some updated name", phone: "some updated phone"}

      assert {:ok, %Customer{} = customer} = Sales.update_customer(customer, update_attrs)
      assert customer.name == "some updated name"
      assert customer.phone == "some updated phone"
    end

    test "update_customer/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Sales.update_customer(customer, @invalid_attrs)
      assert customer == Sales.get_customer!(customer.id)
    end

    test "delete_customer/1 deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = Sales.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Sales.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      customer = customer_fixture()
      assert %Ecto.Changeset{} = Sales.change_customer(customer)
    end
  end

  describe "orders" do
    alias Encomendei.Sales.Order

    import Encomendei.SalesFixtures

    @invalid_attrs %{status: nil, delivery_at: nil, total_cents: nil, notes: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Sales.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Sales.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{status: "some status", delivery_at: ~U[2026-11-09 14:17:00Z], total_cents: 42, notes: "some notes"}

      assert {:ok, %Order{} = order} = Sales.create_order(valid_attrs)
      assert order.status == "some status"
      assert order.delivery_at == ~U[2026-11-09 14:17:00Z]
      assert order.total_cents == 42
      assert order.notes == "some notes"
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sales.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{status: "some updated status", delivery_at: ~U[2026-11-10 14:17:00Z], total_cents: 43, notes: "some updated notes"}

      assert {:ok, %Order{} = order} = Sales.update_order(order, update_attrs)
      assert order.status == "some updated status"
      assert order.delivery_at == ~U[2026-11-10 14:17:00Z]
      assert order.total_cents == 43
      assert order.notes == "some updated notes"
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Sales.update_order(order, @invalid_attrs)
      assert order == Sales.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Sales.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Sales.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Sales.change_order(order)
    end
  end
end
