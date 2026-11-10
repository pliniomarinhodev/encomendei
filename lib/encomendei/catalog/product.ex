defmodule Encomendei.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :description, :string
    field :price_cents, :integer
    field :available, :boolean, default: false
    field :image_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :price_cents, :available, :image_url])
    |> validate_required([:name, :description, :price_cents, :available, :image_url])
  end
end
