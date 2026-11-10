defmodule Encomendei.Reports do
  @moduledoc """
  Consultas de análise de vendas. Pedidos cancelados não entram nos valores
  de faturamento nem nos rankings.
  """

  import Ecto.Query, warn: false
  alias Encomendei.Repo
  alias Encomendei.Sales.{Order, OrderItem}
  alias Encomendei.Catalog.Product

  @doc "Resumo geral: pedidos válidos, faturamento, ticket médio e contagem por status."
  def summary do
    valid = from o in Order, where: o.status != :canceled

    count = Repo.aggregate(valid, :count)
    revenue = Repo.aggregate(valid, :sum, :total_cents) || 0

    by_status =
      from(o in Order, group_by: o.status, select: {o.status, count(o.id)})
      |> Repo.all()
      |> Map.new()

    %{
      orders: count,
      revenue_cents: revenue,
      average_ticket_cents: if(count > 0, do: div(revenue, count), else: 0),
      by_status: Map.merge(%{pending: 0, in_production: 0, delivered: 0, canceled: 0}, by_status)
    }
  end

  @doc "Produtos mais vendidos (quantidade e faturamento), do maior para o menor."
  def top_products(limit \\ 5) do
    from(i in OrderItem,
      join: o in Order,
      on: o.id == i.order_id,
      join: p in Product,
      on: p.id == i.product_id,
      where: o.status != :canceled,
      group_by: [p.id, p.name],
      order_by: [desc: sum(i.quantity), asc: p.name],
      limit: ^limit,
      select: %{
        name: p.name,
        quantity: type(sum(i.quantity), :integer),
        revenue_cents: type(sum(i.quantity * i.unit_price_cents), :integer)
      }
    )
    |> Repo.all()
  end

  @doc "Pedidos e faturamento por semana de entrega (início na segunda), mais recentes primeiro."
  def weekly(limit \\ 8) do
    from(o in Order,
      where: o.status != :canceled,
      group_by: fragment("date_trunc('week', ?)", o.delivery_at),
      order_by: [desc: fragment("date_trunc('week', ?)", o.delivery_at)],
      limit: ^limit,
      select: %{
        week: type(fragment("date_trunc('week', ?)", o.delivery_at), :utc_datetime),
        orders: count(o.id),
        revenue_cents: type(sum(o.total_cents), :integer)
      }
    )
    |> Repo.all()
  end

  @doc "Linhas para exportar em CSV: um item de pedido por linha."
  def export_rows do
    from(i in OrderItem,
      join: o in Order,
      on: o.id == i.order_id,
      join: c in assoc(o, :customer),
      join: p in Product,
      on: p.id == i.product_id,
      order_by: [asc: o.delivery_at, asc: p.name],
      select: %{
        pedido: o.number,
        entrega: o.delivery_at,
        status: o.status,
        cliente: c.name,
        produto: p.name,
        quantidade: i.quantity,
        preco_unitario_cents: i.unit_price_cents
      }
    )
    |> Repo.all()
  end
end
