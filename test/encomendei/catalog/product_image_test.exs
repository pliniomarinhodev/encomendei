defmodule Encomendei.Catalog.ProductImageTest do
  use Encomendei.DataCase, async: true

  alias Encomendei.Catalog
  alias Encomendei.Catalog.Product

  @png <<0x89, "PNG\r\n", 0x1A, "\n", 0, 0, 0, 13, "IHDR">>
  @jpeg <<0xFF, 0xD8, 0xFF, 0xE0, 0, 16, "JFIF">>
  @webp <<"RIFF", 24::little-32, "WEBPVP8 ">>

  defp changeset(attrs),
    do: Product.changeset(%Product{}, Map.merge(%{name: "Bolo", price: "10"}, attrs))

  test "reconhece JPEG, PNG e WebP pelos bytes, não pelo nome" do
    assert Product.detect_image_type(@jpeg) == "image/jpeg"
    assert Product.detect_image_type(@png) == "image/png"
    assert Product.detect_image_type(@webp) == "image/webp"
    assert Product.detect_image_type("<script>alert(1)</script>") == nil
    assert Product.detect_image_type("") == nil
  end

  test "foto enviada válida define o tipo" do
    cs = changeset(%{image_data: @png})
    assert cs.valid?
    assert Ecto.Changeset.get_change(cs, :image_type) == "image/png"
  end

  test "recusa arquivo que não é imagem" do
    cs = changeset(%{image_data: "<html>nao sou imagem</html>"})
    refute cs.valid?
    assert %{image_data: ["envie uma imagem JPG, PNG ou WebP"]} = errors_on(cs)
  end

  test "recusa foto maior que 2 MB" do
    cs = changeset(%{image_data: @png <> :binary.copy(<<0>>, Product.max_image_bytes())})
    refute cs.valid?
    assert %{image_data: ["a foto deve ter até 2 MB"]} = errors_on(cs)
  end

  test "salva, serve pelo contexto e remove a foto enviada" do
    {:ok, product} = Catalog.create_product(%{name: "Bolo", price: "10", image_data: @jpeg})
    assert {"image/jpeg", @jpeg} = Catalog.get_product_image(product.id)
    assert Product.image_src(product) =~ "/imagens/produtos/#{product.id}?v="

    # As listas não carregam os bytes
    assert [%Product{image_type: "image/jpeg"} = listed] = Catalog.list_products()
    refute match?(%Product{image_data: data} when is_binary(data), listed)

    {:ok, product} = Catalog.update_product(product, %{image_data: nil})
    assert product.image_type == nil
    assert Catalog.get_product_image(product.id) == nil
  end

  test "sem foto enviada, usa o link cadastrado" do
    {:ok, product} =
      Catalog.create_product(%{name: "Bolo", price: "10", image_url: "https://x.com/a.jpg"})

    assert Product.image_src(product) == "https://x.com/a.jpg"
    {:ok, product} = Catalog.create_product(%{name: "Torta", price: "10"})
    assert Product.image_src(product) == nil
  end
end
