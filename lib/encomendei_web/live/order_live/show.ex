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

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-3xl font-bold">Pedido recebido!</h1>
      <p>Obrigado, {@order.customer.name}. Guarde esta página para acompanhar sua encomenda.</p>

      <p class="text-lg" aria-live="polite">
        Status: <strong>{status_label(@order.status)}</strong>
      </p>
      <p>Entrega: {datetime(@order.delivery_at)}</p>

      <table class="table">
        <caption class="sr-only">Itens do pedido</caption>
        <thead>
          <tr>
            <th scope="col">Produto</th><th scope="col">Qtd</th><th scope="col">Subtotal</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={i <- @order.items}>
            <td>{i.product.name}</td>
            <td>{i.quantity}</td>
            <td>{money(i.quantity * i.unit_price_cents)}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <th scope="row" colspan="2">Total</th><td>{money(@order.total_cents)}</td>
          </tr>
        </tfoot>
      </table>

      <.link navigate={~p"/"} class="btn">Fazer outro pedido</.link>
    </Layouts.app>
    """
  end
end
