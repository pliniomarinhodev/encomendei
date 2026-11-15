defmodule Encomendei.Repo.Migrations.AddOrderFulfillmentAndCakeMessage do
  use Ecto.Migration

  def change do
    # Pedidos antigos eram todos para entrega, sem mensagem.
    alter table(:orders) do
      add :fulfillment, :string, null: false, default: "delivery"
      add :cake_message, :string
    end

    create constraint(:orders, :fulfillment_valid, check: "fulfillment IN ('delivery', 'pickup')")
  end
end
