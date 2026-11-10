defmodule EncomendeiWeb.OrderLive.Show do
  @moduledoc "Confirmação e acompanhamento do pedido (o link com o id é o acesso do cliente)."
  use EncomendeiWeb, :live_view

  alias Encomendei.Sales
  import EncomendeiWeb.Format

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Sales.fetch_order(id) do
      {:ok, order} ->
        if connected?(socket), do: Sales.subscribe()
        {:ok, assign(socket, page_title: "Pedido", order: order)}

      {:error, :not_found} ->
        {:ok, socket |> put_flash(:error, "Pedido não encontrado.") |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_info({_event, id}, %{assigns: %{order: %{id: id}}} = socket) do
    {:noreply, assign(socket, order: Sales.get_order!(id))}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-2xl space-y-6">
        <.header>
          Pedido recebido!
          <:subtitle>
            Obrigado, {@order.customer.name}. Guarde esta página para acompanhar sua encomenda.
          </:subtitle>
        </.header>

        <div aria-live="polite" class="space-y-3">
          <p class="flex items-center gap-2">Status: <.status_badge status={@order.status} /></p>
          <.status_steps status={@order.status} />
        </div>

        <.list>
          <:item title="Entrega">{datetime(@order.delivery_at)}</:item>
          <:item :if={@order.notes} title="Observações">{@order.notes}</:item>
        </.list>

        <.table id="order-items" rows={@order.items} class="table table-sm">
          <:col :let={item} label="Produto">{item.product.name}</:col>
          <:col :let={item} label="Qtd">{item.quantity}</:col>
          <:col :let={item} label="Subtotal">
            <span class="tabular-nums">{money(item.quantity * item.unit_price_cents)}</span>
          </:col>
        </.table>
        <p class="flex justify-between border-t border-base-300 pt-3 font-semibold">
          <span>Total</span>
          <span class="tabular-nums">{money(@order.total_cents)}</span>
        </p>

        <.button navigate={~p"/"}>Fazer outro pedido</.button>
      </div>
    </Layouts.app>
    """
  end
end
