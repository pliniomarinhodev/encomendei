defmodule Encomendei.Catalog.ProductTest do
  use Encomendei.DataCase, async: true

  alias Encomendei.Catalog.Product

  defp changeset(price), do: Product.changeset(%Product{}, %{name: "Bolo", price: price})

  describe "link da foto" do
    defp image_errors(url) do
      %Product{}
      |> Product.changeset(%{name: "Bolo", price: "10", image_url: url})
      |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
      |> Map.get(:image_url)
    end

    test "aceita http e https e campo vazio" do
      assert image_errors("https://exemplo.com/bolo.jpg") == nil
      assert image_errors("http://exemplo.com/bolo.jpg") == nil
      assert image_errors("") == nil
    end

    test "recusa esquemas que poderiam executar código e links sem endereço" do
      for url <- [
            "javascript:alert(1)",
            "data:text/html;base64,AAAA",
            "ftp://x.com/a.jpg",
            "bolo.jpg",
            "https://"
          ] do
        assert image_errors(url) == ["informe um link começando com https://"], url
      end
    end

    test "recusa links com mais de 255 caracteres" do
      assert image_errors("https://exemplo.com/" <> String.duplicate("a", 260))
    end
  end

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
