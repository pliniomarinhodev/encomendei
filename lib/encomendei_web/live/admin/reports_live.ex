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
    max_qty = assigns.top |> Enum.map(& &1.quantity) |> Enum.max(fn -> 0 end)
    max_rev = assigns.weekly |> Enum.map(& &1.revenue_cents) |> Enum.max(fn -> 0 end)
    assigns = assign(assigns, max_qty: max_qty, max_rev: max_rev)

    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Relatórios</h1>
        <a href={~p"/admin/relatorios/pedidos.csv"} class="btn btn-sm">Baixar CSV</a>
      </div>

      <dl class="grid gap-4 sm:grid-cols-3">
        <div class="card bg-base-200 p-4">
          <dt class="text-sm">Faturamento</dt>
          <dd class="text-2xl font-bold">{money(@summary.revenue_cents)}</dd>
        </div>
        <div class="card bg-base-200 p-4">
          <dt class="text-sm">Pedidos (sem cancelados)</dt>
          <dd class="text-2xl font-bold">{@summary.orders}</dd>
        </div>
        <div class="card bg-base-200 p-4">
          <dt class="text-sm">Ticket médio</dt>
          <dd class="text-2xl font-bold">{money(@summary.average_ticket_cents)}</dd>
        </div>
      </dl>

      <section aria-labelledby="rep-status" class="space-y-2">
        <h2 id="rep-status" class="text-xl font-semibold">Pedidos por status</h2>
        <ul class="flex flex-wrap gap-4">
          <li :for={s <- Encomendei.Sales.Order.statuses()}>
            {status_label(s)}: <strong>{@summary.by_status[s]}</strong>
          </li>
        </ul>
      </section>

      <section aria-labelledby="rep-top" class="space-y-2">
        <h2 id="rep-top" class="text-xl font-semibold">Produtos mais vendidos</h2>
        <p :if={@top == []} class="text-sm">Ainda não há vendas.</p>
        <table :if={@top != []} class="table">
          <caption class="sr-only">Ranking de produtos por quantidade vendida</caption>
          <thead>
            <tr><th scope="col">Produto</th><th scope="col">Quantidade</th><th scope="col">Faturamento</th></tr>
          </thead>
          <tbody>
            <tr :for={p <- @top}>
              <th scope="row" class="font-normal">{p.name}</th>
              <td>
                <div class="flex items-center gap-2">
                  <div class="h-3 rounded bg-primary" style={"width: #{max(pct(p.quantity, @max_qty), 2)}%"} aria-hidden="true"></div>
                  <span class="whitespace-nowrap">{p.quantity}</span>
                </div>
              </td>
              <td>{money(p.revenue_cents)}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section aria-labelledby="rep-week" class="space-y-2">
        <h2 id="rep-week" class="text-xl font-semibold">Faturamento por semana de entrega</h2>
        <p :if={@weekly == []} class="text-sm">Ainda não há vendas.</p>
        <table :if={@weekly != []} class="table">
          <caption class="sr-only">Pedidos e faturamento por semana</caption>
          <thead>
            <tr><th scope="col">Semana</th><th scope="col">Pedidos</th><th scope="col">Faturamento</th></tr>
          </thead>
          <tbody>
            <tr :for={w <- @weekly}>
              <th scope="row" class="font-normal">{week_label(w.week)}</th>
              <td>{w.orders}</td>
              <td>
                <div class="flex items-center gap-2">
                  <div class="h-3 rounded bg-primary" style={"width: #{max(pct(w.revenue_cents, @max_rev), 2)}%"} aria-hidden="true"></div>
                  <span class="whitespace-nowrap">{money(w.revenue_cents)}</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </section>
    </Layouts.app>
    """
  end
end
