defmodule EncomendeiWeb.Admin.ReportsLive do
  @moduledoc "Relatórios de vendas para a confeiteira."
  use EncomendeiWeb, :live_view

  alias Encomendei.{Reports, Sales}
  import EncomendeiWeb.Format

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sales.subscribe()
    {:ok, socket |> assign(page_title: "Relatórios") |> load()}
  end

  @impl true
  def handle_info({_event, _id}, socket), do: {:noreply, load(socket)}

  defp load(socket) do
    assign(socket,
      summary: Reports.summary(),
      top: Reports.top_products(),
      weekly: Reports.weekly()
    )
  end

  defp week_label(%DateTime{} = dt) do
    start = dt |> DateTime.add(-3 * 3600) |> Calendar.strftime("%d/%m")
    "Semana de #{start}"
  end

  # Largura da barra em % relativa ao maior valor (o número sempre aparece em texto)
  defp pct(_value, 0), do: 0
  defp pct(value, max), do: round(value * 100 / max)

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        max_quantity: assigns.top |> Enum.map(& &1.quantity) |> Enum.max(fn -> 0 end),
        max_revenue: assigns.weekly |> Enum.map(& &1.revenue_cents) |> Enum.max(fn -> 0 end)
      )

    ~H"""
    <Layouts.app flash={@flash} nav={:admin} active={:reports}>
      <.header>
        Relatórios
        <:actions>
          <.button href={~p"/admin/relatorios/pedidos.csv"} variant="ghost" size="sm">
            Baixar CSV
          </.button>
        </:actions>
      </.header>

      <dl class="grid divide-y divide-base-300 border border-base-300 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
        <div class="p-4">
          <dt class="text-sm text-base-content/70">Faturamento</dt>
          <dd class="text-2xl font-semibold tabular-nums">{money(@summary.revenue_cents)}</dd>
        </div>
        <div class="p-4">
          <dt class="text-sm text-base-content/70">Pedidos (sem cancelados)</dt>
          <dd class="text-2xl font-semibold tabular-nums">{@summary.orders}</dd>
        </div>
        <div class="p-4">
          <dt class="text-sm text-base-content/70">Ticket médio</dt>
          <dd class="text-2xl font-semibold tabular-nums">{money(@summary.average_ticket_cents)}</dd>
        </div>
      </dl>

      <ul class="flex flex-wrap gap-x-6 gap-y-1 text-sm" aria-label="Pedidos por status">
        <li :for={status <- Encomendei.Sales.Order.statuses()} class="flex items-center gap-2">
          <.status_badge status={status} />
          <strong class="tabular-nums">{@summary.by_status[status]}</strong>
        </li>
      </ul>

      <div class="grid gap-10 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <section aria-labelledby="rep-top" class="space-y-2">
          <h2 id="rep-top" class="text-sm font-semibold">Produtos mais vendidos</h2>
          <p :if={@top == []} class="text-sm text-base-content/70">Ainda não há vendas.</p>
          <.table :if={@top != []} id="top-products" rows={@top} class="table table-sm">
            <:col :let={product} label="Produto">{product.name}</:col>
            <:col :let={product} label="Quantidade">
              <.bar value={product.quantity} max={@max_quantity}>{product.quantity}</.bar>
            </:col>
            <:col :let={product} label="Faturamento">
              <span class="tabular-nums">{money(product.revenue_cents)}</span>
            </:col>
          </.table>
        </section>

        <section aria-labelledby="rep-week" class="space-y-2">
          <h2 id="rep-week" class="text-sm font-semibold">Faturamento por semana de entrega</h2>
          <p :if={@weekly == []} class="text-sm text-base-content/70">Ainda não há vendas.</p>
          <.table :if={@weekly != []} id="weekly" rows={@weekly} class="table table-sm">
            <:col :let={week} label="Semana">{week_label(week.week)}</:col>
            <:col :let={week} label="Pedidos">{week.orders}</:col>
            <:col :let={week} label="Faturamento">
              <.bar value={week.revenue_cents} max={@max_revenue}>{money(week.revenue_cents)}</.bar>
            </:col>
          </.table>
        </section>
      </div>
    </Layouts.app>
    """
  end

  attr :value, :integer, required: true
  attr :max, :integer, required: true
  slot :inner_block, required: true

  defp bar(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <div class="h-2 bg-primary" style={"width: #{max(pct(@value, @max), 2)}%"} aria-hidden="true">
      </div>
      <span class="whitespace-nowrap tabular-nums">{render_slot(@inner_block)}</span>
    </div>
    """
  end
end
