defmodule Encomendei.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :price_cents, :integer
      add :available, :boolean, default: false, null: false
      add :image_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
