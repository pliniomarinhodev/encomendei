defmodule Encomendei.Catalog.ProductTest do
  use Encomendei.DataCase, async: true

  alias Encomendei.Catalog.Product

  defp changeset(price), do: Product.changeset(%Product{}, %{name: "Bolo", price: price})

  test "converte preço em reais para centavos" do
    for {input, cents} <- [
          {"45", 4500},
          {"45,5", 4550},
          {"45,50", 4550},
          {"45.50", 4550},
          {"R$ 45,50", 4550},
          {"0,99", 99}
        ] do
      assert %{valid?: true} = cs = changeset(input)

      assert Ecto.Changeset.get_field(cs, :price_cents) == cents,
             "esperava #{cents} para #{inspect(input)}"
    end
  end

  test "rejeita preço malformado, zero ou negativo" do
    for input <- ["abc", "45,555", "1.234,50", "-5", "0", "0,00"] do
      cs = changeset(input)
      refute cs.valid?, "deveria rejeitar #{inspect(input)}"
      assert errors_on(cs)[:price] || errors_on(cs)[:price_cents]
    end
  end

  test "continua aceitando price_cents diretamente" do
    assert %{valid?: true} = Product.changeset(%Product{}, %{name: "Bolo", price_cents: 1200})
  end
end
