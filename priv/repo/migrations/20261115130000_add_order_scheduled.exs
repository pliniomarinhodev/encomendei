defmodule Encomendei.Repo.Migrations.AddOrderScheduled do
  use Ecto.Migration

  def change do
    # Pedidos antigos sempre tiveram data marcada pelo cliente.
    alter table(:orders) do
      add :scheduled, :boolean, null: false, default: true
    end
  end
end
