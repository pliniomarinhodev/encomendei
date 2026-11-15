defmodule Encomendei.Repo.Migrations.CreateShopSettings do
  use Ecto.Migration

  def change do
    # Uma única linha (id = 1): nome e logo da confeitaria que usa o sistema.
    create table(:shop_settings, primary_key: false) do
      add :id, :integer, primary_key: true
      add :name, :string, null: false, default: "Encomendei"
      add :logo_data, :binary
      add :logo_type, :string

      timestamps(type: :utc_datetime)
    end

    create constraint(:shop_settings, :single_row, check: "id = 1")

    create constraint(:shop_settings, :logo_data_with_type,
             check: "(logo_data IS NULL) = (logo_type IS NULL)"
           )
  end
end
