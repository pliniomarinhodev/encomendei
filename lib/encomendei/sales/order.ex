defmodule Encomendei.Sales.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:pending, :in_production, :delivered, :canceled]

  schema "orders" do
    field :delivery_at, :utc_datetime
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :total_cents, :integer, default: 0
    field :notes, :string

    belongs_to :customer, Encomendei.Sales.Customer
    has_many :items, Encomendei.Sales.OrderItem

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:delivery_at, :notes, :customer_id, :total_cents])
    |> validate_required([:delivery_at, :customer_id])
    |> validate_length(:notes, max: 500)
    |> validate_change(:delivery_at, fn :delivery_at, at ->
      if DateTime.compare(at, DateTime.utc_now()) == :gt,
        do: [],
        else: [delivery_at: "deve ser uma data futura"]
    end)
  end

  def status_changeset(order, status) do
    order |> cast(%{status: status}, [:status]) |> validate_required([:status])
  end
end
