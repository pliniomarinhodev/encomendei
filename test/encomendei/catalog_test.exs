defmodule Encomendei.CatalogTest do
  use Encomendei.DataCase

  alias Encomendei.Catalog

  describe "products" do
    alias Encomendei.Catalog.Product

    import Encomendei.CatalogFixtures

    @invalid_attrs %{
      name: nil,
      description: nil,
      available: nil,
      price_cents: nil,
      image_url: nil
    }

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Catalog.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Catalog.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        available: true,
        price_cents: 42,
        image_url: "some image_url"
      }

      assert {:ok, %Product{} = product} = Catalog.create_product(valid_attrs)
      assert product.name == "some name"
      assert product.description == "some description"
      assert product.available == true
      assert product.price_cents == 42
      assert product.image_url == "some image_url"
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Catalog.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        available: false,
        price_cents: 43,
        image_url: "some updated image_url"
      }

      assert {:ok, %Product{} = product} = Catalog.update_product(product, update_attrs)
      assert product.name == "some updated name"
      assert product.description == "some updated description"
      assert product.available == false
      assert product.price_cents == 43
      assert product.image_url == "some updated image_url"
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Catalog.update_product(product, @invalid_attrs)
      assert product == Catalog.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Catalog.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Catalog.change_product(product)
    end
  end

  test "preço zero ou negativo é rejeitado também pelo banco" do
    alias Encomendei.{Catalog.Product, Repo}

    assert {:error, changeset} =
             %Product{name: "Bolo"}
             |> Ecto.Changeset.change(price_cents: 0)
             |> Ecto.Changeset.check_constraint(:price_cents, name: :price_cents_positive)
             |> Repo.insert()

    assert %{price_cents: ["is invalid"]} = errors_on(changeset)
  end
end
