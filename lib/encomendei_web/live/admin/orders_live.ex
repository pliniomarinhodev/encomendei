defmodule EncomendeiWeb.Admin.OrdersLive do
  @moduledoc "Painel da confeiteira: fila de produção agrupada por status, em tempo real."
  use EncomendeiWeb, :live_view

  alias Encomendei.Sales
  alias Encomendei.Sales.Order
  import EncomendeiWeb.Format

  @groups [:pending, :in_production, :delivered]
  @open [:pending, :in_production]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sales.subscribe()
    {:ok, socket |> assign(page_title: "Pedidos", groups: @groups) |> load()}
  end

  @impl true
  def handle_info({_event, _order_id}, socket), do: {:noreply, load(socket)}

  @impl true
  def handle_event("status", %{"id" => id, "to" => to}, socket) do
    with {:ok, order} <- Sales.fetch_order(id),
         {:ok, status} <- Order.parse_status(to),
         {:ok, _order} <- Sales.update_status(order, status) do
      {:noreply, socket}
    else
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Essa mudança de status não é permitida.")}
    end
  end

  defp load(socket) do
    queue = Sales.production_queue()
    now = DateTime.utc_now()
    open = Enum.flat_map(@open, &Map.fetch!(queue, &1))

    @groups
    |> Enum.reduce(socket, fn status, acc ->
      stream(acc, status, Map.fetch!(queue, status), reset: true, dom_id: &"order-#{&1.id}")
    end)
    |> assign(
      now: now,
      counts: Map.new(@groups, &{&1, length(Map.fetch!(queue, &1))}),
      totals: Map.new(@groups, &{&1, total_cents(Map.fetch!(queue, &1))}),
      open_total: total_cents(open),
      overdue: Enum.filter(open, &(urgency(&1, now) == :overdue)),
      today: Enum.filter(open, &(urgency(&1, now) == :today))
    )
  end

  defp action_label(:in_production), do: "Iniciar produção"
  defp action_label(:delivered), do: "Marcar entregue"
  defp action_label(:canceled), do: "Cancelar"

  defp action_variant(:canceled), do: "ghost"
  defp action_variant(_advance), do: nil

  defp confirmation(:canceled), do: "Cancelar este pedido?"
  defp confirmation(_advance), do: nil

  defp overdue_title(1), do: "1 atrasada"
  defp overdue_title(count), do: "#{count} atrasadas"

  defp whatsapp_url(order) do
    text =
      "Olá, #{order.customer.name}! Sobre o seu pedido #{order_number(order)} na Encomendei: "

    "https://wa.me/55#{order.customer.phone}?" <> URI.encode_query([text: text], :rfc3986)
  end

  attr :status, :atom, required: true
  attr :rows, :any, required: true
  attr :count, :integer, required: true
  attr :total, :integer, required: true
  attr :now, DateTime, required: true

  defp status_group(assigns) do
    ~H"""
    <section id={"group-#{@status}"} aria-labelledby={"title-#{@status}"}>
      <div class="flex items-baseline justify-between border-b border-base-300 pb-2">
        <h2 id={"title-#{@status}"} class="flex items-center gap-2 text-sm font-semibold">
          <.status_badge status={@status} />
          <span class="font-normal text-base-content/70">{@count}</span>
        </h2>
        <p class="text-sm text-base-content/70 tabular-nums">{money(@total)}</p>
      </div>

      <p :if={@count == 0} class="py-4 text-sm text-base-content/70">Nenhum pedido.</p>

      <.table
        :if={@count > 0}
        id={"orders-#{@status}"}
        rows={@rows}
        class="table table-sm"
        row_item={fn {_dom_id, order} -> order end}
      >
        <:col :let={order} label="Nº">
          <span class="whitespace-nowrap tabular-nums font-medium">{order_number(order)}</span>
        </:col>
        <:col :let={order} label="Cliente">
          <p class="whitespace-nowrap font-medium">{order.customer.name}</p>
          <p class="whitespace-nowrap text-xs text-base-content/70">{phone(order.customer.phone)}</p>
        </:col>
        <:col :let={order} label="Itens">
          <p>{items_summary(order)}</p>
          <p :if={order.notes} class="text-xs italic text-base-content/70">“{order.notes}”</p>
        </:col>
        <:col :let={order} label="Entrega">
          <p class="whitespace-nowrap">{delivery_short(order.delivery_at)}</p>
          <.urgency_badge :if={@status != :delivered} urgency={urgency(order, @now)} />
        </:col>
        <:col :let={order} label="Total">
          <span class="whitespace-nowrap tabular-nums">{money(order.total_cents)}</span>
        </:col>
        <:action :let={order}>
          <div class="flex items-center gap-1 whitespace-nowrap">
            <.button
              :for={to <- Sales.next_statuses(order)}
              type="button"
              size="sm"
              variant={action_variant(to)}
              phx-click="status"
              phx-value-id={order.id}
              phx-value-to={to}
              data-confirm={confirmation(to)}
            >
              {action_label(to)}
            </.button>
            <.button
              href={whatsapp_url(order)}
              target="_blank"
              rel="noopener"
              variant="ghost"
              size="sm"
            >
              WhatsApp
            </.button>
          </div>
        </:action>
      </.table>
    </section>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} nav={:admin} active={:orders}>
      <.header>
        Pedidos
        <:subtitle>
          {@counts.pending + @counts.in_production} em aberto · {money(@open_total)} a receber
        </:subtitle>
      </.header>

      <div class="grid gap-8 xl:grid-cols-[minmax(0,1fr)_17rem] xl:items-start">
        <div class="space-y-8">
          <.status_group
            :for={status <- @groups}
            status={status}
            rows={@streams[status]}
            count={@counts[status]}
            total={@totals[status]}
            now={@now}
          />
        </div>

        <aside aria-label="Resumo do dia" class="space-y-5 xl:sticky xl:top-6">
          <section
            :if={@overdue != []}
            aria-labelledby="titulo-atrasadas"
            class="border-l-4 border-error pl-3"
          >
            <h2 id="titulo-atrasadas" class="text-sm font-semibold text-error">
              {overdue_title(length(@overdue))}
            </h2>
            <ul class="mt-1 space-y-1 text-sm">
              <li :for={order <- @overdue}>
                <span class="tabular-nums">{order_number(order)}</span>
                {order.customer.name}
                <span class="text-base-content/70">· {delivery_short(order.delivery_at)}</span>
              </li>
            </ul>
          </section>

          <section aria-labelledby="titulo-hoje">
            <h2 id="titulo-hoje" class="text-sm font-semibold">Entregas de hoje</h2>
            <p :if={@today == []} class="mt-1 text-sm text-base-content/70">Nada para hoje.</p>
            <ul class="mt-1 divide-y divide-base-300 text-sm">
              <li :for={order <- @today} class="flex justify-between gap-2 py-1.5">
                <span><span class="tabular-nums">{order_number(order)}</span> {order.customer.name}</span>
                <span class="tabular-nums text-base-content/70">{delivery_short(order.delivery_at)}</span>
              </li>
            </ul>
          </section>
        </aside>
      </div>
    </Layouts.app>
    """
  end
end
