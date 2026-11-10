defmodule Encomendei.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Encomendei.Catalog` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        available: true,
        description: "some description",
        image_url: "some image_url",
        name: "some name",
        price_cents: 42
      })
      |> Encomendei.Catalog.create_product()

    product
  end
end
