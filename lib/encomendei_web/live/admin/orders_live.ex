defmodule EncomendeiWeb.Admin.OrdersLive do
  @moduledoc "Painel da confeiteira: fila de produção agrupada por status, em tempo real."
  use EncomendeiWeb, :live_view

  alias Encomendei.Sales
  alias Encomendei.Sales.Order
  import EncomendeiWeb.Format

  @groups [:pending, :in_production, :delivered, :canceled]
  @open [:pending, :in_production]
  @flash_ms 6_000
  @scopes ~w(all overdue today tomorrow)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sales.subscribe()

    {:ok,
     socket
     |> assign(page_title: "Pedidos", groups: @groups, highlight: nil, query: "", scope: "all")
     |> load()}
  end

  @impl true
  def handle_info({:order_created, id}, socket) do
    socket =
      case Sales.fetch_order(id) do
        {:ok, order} ->
          notify(socket, "Novo pedido #{order_number(order)} de #{order.customer.name}.", id)

        {:error, :not_found} ->
          socket
      end

    {:noreply, load(socket)}
  end

  def handle_info({_event, _order_id}, socket), do: {:noreply, load(socket)}
  def handle_info(:clear_flash, socket), do: {:noreply, clear_flash(socket)}

  defp notify(socket, message, id) do
    Process.send_after(self(), :clear_flash, @flash_ms)
    socket |> put_flash(:info, message) |> assign(highlight: id)
  end

  @impl true
  def handle_event("filter", %{"q" => query, "scope" => scope}, socket) do
    scope = if scope in @scopes, do: scope, else: "all"
    {:noreply, socket |> assign(query: query, scope: scope) |> load()}
  end

  def handle_event("status", %{"id" => id, "to" => to}, socket) do
    with {:ok, order} <- Sales.fetch_order(id),
         {:ok, status} <- Order.parse_status(to),
         {:ok, updated} <- Sales.update_status(order, status) do
      message = "Pedido #{order_number(updated)} #{status_done(status)}."
      {:noreply, notify(socket, message, updated.id)}
    else
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Essa mudança de status não é permitida.")}
    end
  end

  defp load(socket) do
    queue = Sales.production_queue()
    now = DateTime.utc_now()
    open = Enum.flat_map(@open, &Map.fetch!(queue, &1))

    %{query: query, scope: scope} = socket.assigns

    visible =
      Map.new(queue, fn {status, orders} ->
        {status, filter_orders(orders, status, query, scope, now)}
      end)

    @groups
    |> Enum.reduce(socket, fn status, acc ->
      stream(acc, status, Map.fetch!(visible, status), reset: true, dom_id: &"order-#{&1.id}")
    end)
    |> assign(
      now: now,
      counts: Map.new(@groups, &{&1, length(Map.fetch!(visible, &1))}),
      totals: Map.new(@groups, &{&1, total_cents(Map.fetch!(visible, &1))}),
      open_count: length(open),
      open_total: total_cents(open),
      overdue: Enum.filter(open, &(urgency(&1, now) == :overdue)),
      today: Enum.filter(open, &(urgency(&1, now) == :today))
    )
  end

  # O filtro por data de entrega só vale para pedidos em aberto; entregues e
  # cancelados somem quando se filtra por urgência.
  defp filter_orders(orders, status, query, scope, now) do
    Enum.filter(orders, &(matches_query?(&1, query) and matches_scope?(&1, status, scope, now)))
  end

  defp matches_scope?(_order, _status, "all", _now), do: true
  defp matches_scope?(_order, status, _scope, _now) when status not in @open, do: false

  defp matches_scope?(order, _status, scope, now),
    do: urgency(order, now) == String.to_existing_atom(scope)

  defp matches_query?(order, query) do
    case query |> normalize_text() |> String.trim_leading("#") do
      "" ->
        true

      term ->
        name_matches?(order, term) or number_matches?(order, term) or phone_matches?(order, term)
    end
  end

  defp name_matches?(order, term),
    do: order.customer.name |> normalize_text() |> String.contains?(term)

  defp number_matches?(order, term), do: Integer.to_string(order.number) == term

  defp phone_matches?(order, term) do
    case String.replace(term, ~r/\D/, "") do
      "" -> false
      digits -> String.contains?(order.customer.phone, digits)
    end
  end

  defp normalize_text(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
  end

  defp advances(order), do: Enum.reject(Sales.next_statuses(order), &(&1 == :canceled))
  defp cancelable?(order), do: :canceled in Sales.next_statuses(order)

  defp status_done(:in_production), do: "em produção"
  defp status_done(:delivered), do: "entregue"
  defp status_done(:canceled), do: "cancelado"

  defp action_label(:in_production), do: "Iniciar produção"
  defp action_label(:delivered), do: "Marcar entregue"
  defp action_label(:canceled), do: "Cancelar"

  defp overdue_title(1), do: "1 atrasada"
  defp overdue_title(count), do: "#{count} atrasadas"

  defp whatsapp_url(order) do
    text =
      "Olá, #{order.customer.name}! Sobre o seu pedido #{order_number(order)} na Encomendei: "

    whatsapp_url(order.customer.phone, text)
  end

  attr :status, :atom, required: true
  attr :rows, :any, required: true
  attr :count, :integer, required: true
  attr :total, :integer, required: true
  attr :now, DateTime, required: true
  attr :highlight, :string, default: nil

  defp status_group(assigns) do
    ~H"""
    <section
      :if={@status != :canceled or @count > 0}
      id={"group-#{@status}"}
      aria-labelledby={"title-#{@status}"}
    >
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
        class="table table-sm orders-stack"
        row_item={fn {_dom_id, order} -> order end}
        row_class={fn order -> order.id == @highlight && "row-highlight" end}
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
          <p :if={order.cake_message} class="text-xs">
            <span class="font-medium">Mensagem no bolo:</span> “{order.cake_message}”
          </p>
          <p :if={order.notes} class="text-xs italic text-base-content/70">“{order.notes}”</p>
        </:col>
        <:col :let={order} label="Entrega">
          <p class="whitespace-nowrap">
            <span :if={order.fulfillment == :pickup} class="badge badge-neutral badge-sm mr-1">
              Retirada
            </span>
            {delivery_label(order)}
          </p>
          <.urgency_badge :if={@status in [:pending, :in_production]} urgency={urgency(order, @now)} />
        </:col>
        <:col :let={order} label="Total">
          <span class="whitespace-nowrap tabular-nums">{money(order.total_cents)}</span>
        </:col>
        <:action :let={order}>
          <div class="flex items-center gap-1 whitespace-nowrap">
            <.button
              :for={to <- advances(order)}
              type="button"
              size="sm"
              phx-click="status"
              phx-value-id={order.id}
              phx-value-to={to}
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
            <.button
              :if={cancelable?(order)}
              type="button"
              class="btn btn-ghost btn-sm text-error sm:ml-4"
              phx-click="status"
              phx-value-id={order.id}
              phx-value-to="canceled"
              data-confirm="Cancelar este pedido?"
            >
              Cancelar
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
          {@open_count} em aberto · {money(@open_total)} a receber
        </:subtitle>
      </.header>

      <form
        id="order-filter"
        role="search"
        phx-change="filter"
        phx-submit="filter"
        class="flex flex-wrap items-center gap-3"
      >
        <label class="flex-1 sm:max-w-xs">
          <span class="sr-only">Buscar pedido por nome, telefone ou número</span>
          <input
            type="search"
            name="q"
            value={@query}
            placeholder="Buscar nome, telefone ou nº"
            phx-debounce="250"
            autocomplete="off"
            class="input w-full"
          />
        </label>
        <label class="flex items-center gap-2 text-sm">
          <span>Entrega</span>
          <select name="scope" class="select select-sm w-auto">
            <option value="all" selected={@scope == "all"}>Todas</option>
            <option value="overdue" selected={@scope == "overdue"}>Atrasadas</option>
            <option value="today" selected={@scope == "today"}>Hoje</option>
            <option value="tomorrow" selected={@scope == "tomorrow"}>Amanhã</option>
          </select>
        </label>
      </form>

      <div class="grid gap-8 xl:grid-cols-[minmax(0,1fr)_17rem] xl:items-start">
        <div class="space-y-8">
          <.status_group
            :for={status <- @groups}
            status={status}
            rows={@streams[status]}
            count={@counts[status]}
            total={@totals[status]}
            now={@now}
            highlight={@highlight}
          />
        </div>

        <aside
          aria-label="Resumo do dia"
          class="order-first space-y-5 xl:sticky xl:top-6 xl:order-none"
        >
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
                <span class="text-base-content/70">· {delivery_label(order)}</span>
              </li>
            </ul>
          </section>

          <section aria-labelledby="titulo-hoje">
            <h2 id="titulo-hoje" class="text-sm font-semibold">Entregas de hoje</h2>
            <p :if={@today == []} class="mt-1 text-sm text-base-content/70">Nada para hoje.</p>
            <ul class="mt-1 divide-y divide-base-300 text-sm">
              <li :for={order <- @today} class="flex justify-between gap-2 py-1.5">
                <span><span class="tabular-nums">{order_number(order)}</span> {order.customer.name}</span>
                <span class="tabular-nums text-base-content/70">{delivery_label(order)}</span>
              </li>
            </ul>
          </section>
        </aside>
      </div>
    </Layouts.app>
    """
  end
end
