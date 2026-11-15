defmodule EncomendeiWeb.API.JSON do
  @moduledoc "Serialização das respostas da API."

  def product(p) do
    %{
      id: p.id,
      name: p.name,
      description: p.description,
      price_cents: p.price_cents,
      image_url: Encomendei.Catalog.Product.image_src(p)
    }
  end

  def order(o) do
    %{
      id: o.id,
      number: o.number,
      status: o.status,
      delivery_at: o.delivery_at,
      scheduled: o.scheduled,
      total_cents: o.total_cents,
      notes: o.notes,
      customer: %{name: o.customer.name, phone: o.customer.phone},
      items:
        for i <- o.items do
          %{
            product_id: i.product_id,
            name: i.product.name,
            quantity: i.quantity,
            unit_price_cents: i.unit_price_cents
          }
        end
    }
  end

  def changeset_errors(%Ecto.Changeset{} = cs) do
    Ecto.Changeset.traverse_errors(cs, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
