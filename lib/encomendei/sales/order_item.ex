defmodule Encomendei.Sales.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "order_items" do
    field :quantity, :integer
    field :unit_price_cents, :integer

    belongs_to :order, Encomendei.Sales.Order
    belongs_to :product, Encomendei.Catalog.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:quantity, :unit_price_cents, :order_id, :product_id])
    |> validate_required([:quantity, :unit_price_cents, :product_id])
    |> validate_number(:quantity, greater_than: 0, less_than_or_equal_to: 99)
    |> validate_number(:unit_price_cents, greater_than_or_equal_to: 0)
    |> assoc_constraint(:order)
    |> assoc_constraint(:product)
    |> check_constraint(:quantity, name: :quantity_positive)
    |> check_constraint(:unit_price_cents, name: :unit_price_non_negative)
  end
end
