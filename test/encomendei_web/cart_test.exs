defmodule EncomendeiWeb.CartTest do
  use ExUnit.Case, async: true

  alias Encomendei.Catalog.Product
  alias EncomendeiWeb.Cart

  @bolo %Product{id: "a", name: "Bolo", price_cents: 5000}
  @torta %Product{id: "b", name: "Torta", price_cents: 3000}

  test "add soma de um em um e limita em 99" do
    cart = Cart.new() |> Cart.add("a") |> Cart.add("a")
    assert Cart.quantity(cart, @bolo) == 2

    full = Enum.reduce(1..120, Cart.new(), fn _, acc -> Cart.add(acc, "a") end)
    assert Cart.quantity(full, @bolo) == 99
  end

  test "remove diminui e tira o produto ao chegar em zero" do
    cart = Cart.new() |> Cart.add("a") |> Cart.add("a") |> Cart.remove("a")
    assert Cart.quantity(cart, @bolo) == 1
    assert Cart.new() |> Cart.add("a") |> Cart.remove("a") |> Cart.empty?()
  end

  test "remover item ausente não altera o carrinho" do
    assert Cart.remove(Cart.new(), "zzz") == %{}
  end

  test "lines/2 respeita a ordem do cardápio e calcula subtotais e total" do
    cart = Cart.new() |> Cart.add("b") |> Cart.add("a") |> Cart.add("a")
    products = [@bolo, @torta]

    assert [
             %{product: @bolo, quantity: 2, subtotal_cents: 10_000},
             %{product: @torta, quantity: 1, subtotal_cents: 3000}
           ] =
             Cart.lines(cart, products)

    assert Cart.total_cents(cart, products) == 13_000
  end

  test "to_items/1 monta o formato de Sales.place_order/1" do
    assert [%{"product_id" => "a", "quantity" => 2}] =
             Cart.new() |> Cart.add("a") |> Cart.add("a") |> Cart.to_items()
  end
end
