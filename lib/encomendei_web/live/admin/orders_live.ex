defmodule EncomendeiWeb.Admin.OrdersLive do
  @moduledoc "Painel da confeiteira: fila de produção atualizada em tempo real."
  use EncomendeiWeb, :live_view

  alias Encomendei.Sales
  import EncomendeiWeb.Format

  @columns [:pending, :in_production, :delivered]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Sales.subscribe()
    {:ok, socket |> assign(page_title: "Painel de pedidos", columns: @columns) |> load()}
  end

  @impl true
  def handle_info({_event, _id}, socket), do: {:noreply, load(socket)}

  @impl true
  def handle_event("status", %{"id" => id, "to" => to}, socket) do
    to = String.to_existing_atom(to)
    order = Sales.get_order!(id)

    case Sales.update_status(order, to) do
      {:ok, _} ->
        {:noreply, load(socket)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Essa mudança de status não é permitida.")}
    end
  end

  defp load(socket) do
    orders = Sales.list_orders(status: @columns) |> Enum.group_by(& &1.status)
    assign(socket, orders: orders)
  end

  defp wa_link(order) do
    "https://wa.me/55#{order.customer.phone}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Pedidos</h1>
        <.link navigate={~p"/admin/produtos"} class="btn btn-sm">Gerenciar produtos</.link>
      </div>

      <div class="grid gap-4 md:grid-cols-3">
        <section :for={status <- @columns} aria-labelledby={"col-#{status}"} class="space-y-3">
          <h2 id={"col-#{status}"} class="text-lg font-semibold">
            {status_label(status)} ({length(Map.get(@orders, status, []))})
          </h2>
          <p :if={Map.get(@orders, status, []) == []} class="text-sm text-base-content/60">
            Nenhum pedido.
          </p>

          <article
            :for={order <- Map.get(@orders, status, [])}
            id={"order-#{order.id}"}
            class="card bg-base-200 p-3 space-y-2"
          >
            <h3 class="font-semibold">{order.customer.name}</h3>
            <p class="text-sm">Entrega: {datetime(order.delivery_at)}</p>
            <ul class="text-sm list-disc pl-5">
              <li :for={i <- order.items}>{i.quantity}× {i.product.name}</li>
            </ul>
            <p :if={order.notes} class="text-sm italic">“{order.notes}”</p>
            <p class="font-bold">{money(order.total_cents)}</p>
            <div class="flex flex-wrap gap-2">
              <button
                :for={next <- Sales.next_statuses(order)}
                type="button"
                class="btn btn-xs"
                phx-click="status"
                phx-value-id={order.id}
                phx-value-to={next}
              >
                {if next == :canceled, do: "Cancelar", else: "Mover para " <> status_label(next)}
              </button>
              <a href={wa_link(order)} target="_blank" rel="noopener" class="btn btn-xs btn-ghost">
                WhatsApp {phone(order.customer.phone)}
              </a>
            </div>
          </article>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
