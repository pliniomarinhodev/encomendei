defmodule Encomendei.Repo.Migrations.HardenOrdersSchema do
  use Ecto.Migration

  def up do
    execute "UPDATE orders SET status = 'pending' WHERE status IS NULL"
    execute "UPDATE orders SET total_cents = 0 WHERE total_cents IS NULL"

    alter table(:orders) do
      add :number, :bigint, generated: "BY DEFAULT AS IDENTITY"
      modify :status, :string, null: false, default: "pending"
      modify :total_cents, :integer, null: false, default: 0
      modify :delivery_at, :utc_datetime, null: false
      modify :customer_id, :binary_id, null: false
    end

    alter table(:order_items) do
      modify :quantity, :integer, null: false
      modify :unit_price_cents, :integer, null: false
      modify :order_id, :binary_id, null: false
      modify :product_id, :binary_id, null: false
    end

    create unique_index(:orders, [:number])
    create index(:orders, [:status, :delivery_at])
    create index(:orders, [:inserted_at])

    create constraint(:orders, :total_cents_non_negative, check: "total_cents >= 0")

    create constraint(:orders, :status_valid,
             check: "status IN ('pending', 'in_production', 'delivered', 'canceled')"
           )

    create constraint(:order_items, :quantity_positive, check: "quantity > 0")
    create constraint(:order_items, :unit_price_non_negative, check: "unit_price_cents >= 0")
  end

  def down do
    drop constraint(:order_items, :unit_price_non_negative)
    drop constraint(:order_items, :quantity_positive)
    drop constraint(:orders, :status_valid)
    drop constraint(:orders, :total_cents_non_negative)

    drop index(:orders, [:inserted_at])
    drop index(:orders, [:status, :delivery_at])
    drop index(:orders, [:number])

    alter table(:order_items) do
      modify :product_id, :binary_id, null: true
      modify :order_id, :binary_id, null: true
      modify :unit_price_cents, :integer, null: true
      modify :quantity, :integer, null: true
    end

    alter table(:orders) do
      modify :customer_id, :binary_id, null: true
      modify :delivery_at, :utc_datetime, null: true
      modify :total_cents, :integer, null: true, default: nil
      modify :status, :string, null: true, default: nil
      remove :number
    end
  end
end
