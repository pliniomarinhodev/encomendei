defmodule Encomendei.Repo.Migrations.AddProductPriceCheck do
  use Ecto.Migration

  def up do
    alter table(:products) do
      modify :name, :string, null: false
      modify :price_cents, :integer, null: false
    end

    create constraint(:products, :price_cents_positive, check: "price_cents > 0")
  end

  def down do
    drop constraint(:products, :price_cents_positive)

    alter table(:products) do
      modify :price_cents, :integer, null: true
      modify :name, :string, null: true
    end
  end
end
