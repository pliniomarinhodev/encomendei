defmodule Encomendei.Sales.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "customers" do
    field :name, :string
    field :phone, :string

    has_many :orders, Encomendei.Sales.Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:name, :phone])
    |> update_change(:phone, &normalize_phone/1)
    |> validate_required([:name, :phone])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:phone, min: 10, max: 13, message: "informe DDD + número")
  end

  defp normalize_phone(nil), do: nil
  defp normalize_phone(phone), do: String.replace(phone, ~r/\D/, "")
end
