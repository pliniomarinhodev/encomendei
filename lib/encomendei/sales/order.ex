defmodule Encomendei.Sales.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "orders" do
    field :delivery_at, :utc_datetime
    field :status, :string
    field :total_cents, :integer
    field :notes, :string
    field :customer_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:delivery_at, :status, :total_cents, :notes])
    |> validate_required([:delivery_at, :status, :total_cents, :notes])
  end
end
