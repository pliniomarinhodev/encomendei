defmodule Encomendei.Repo.Migrations.AddProductImageUpload do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :image_data, :binary
      add :image_type, :string
    end

    # A foto enviada e o seu tipo existem juntos ou não existem.
    create constraint(:products, :image_data_with_type,
             check: "(image_data IS NULL) = (image_type IS NULL)"
           )
  end
end
