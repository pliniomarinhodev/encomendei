defmodule Encomendei.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :delivery_at, :utc_datetime
      add :status, :string
      add :total_cents, :integer
      add :notes, :text
      add :customer_id, references(:customers, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:customer_id])
  end
end
