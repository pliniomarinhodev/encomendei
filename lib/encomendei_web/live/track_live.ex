defmodule EncomendeiWeb.TrackLive do
  @moduledoc "O cliente reencontra o pedido pelo número e pelo telefone, sem precisar de conta."
  use EncomendeiWeb, :live_view

  alias Encomendei.Sales

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Acompanhar pedido", form: track_form(%{}), error: nil)}
  end

  @impl true
  def handle_event("find", %{"track" => %{"number" => number, "phone" => phone} = params}, socket) do
    case Sales.fetch_order_by_contact(number, phone) do
      {:ok, order} ->
        {:noreply, push_navigate(socket, to: ~p"/pedido/#{order.id}")}

      {:error, :not_found} ->
        message =
          "Não encontramos um pedido com esse número e telefone. Confira os dados da confirmação."

        {:noreply, assign(socket, form: track_form(params), error: message)}
    end
  end

  defp track_form(params), do: to_form(params, as: :track)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active={:track}>
      <div class="mx-auto max-w-md space-y-6 py-4">
        <.header>
          Acompanhar pedido
          <:subtitle>
            Informe o número do pedido (aparece na confirmação, por exemplo #12) e o telefone usado na encomenda.
          </:subtitle>
        </.header>

        <.form for={@form} id="track-form" phx-submit="find">
          <.input field={@form[:number]} label="Número do pedido" inputmode="numeric" required />
          <.input
            field={@form[:phone]}
            type="tel"
            label="Telefone com DDD"
            autocomplete="tel"
            required
          />
          <p :if={@error} role="alert" class="mb-2 text-sm text-error">{@error}</p>
          <.button type="submit" variant="primary" class="btn btn-primary w-full">
            Ver meu pedido
          </.button>
        </.form>

        <p class="text-center text-sm">
          <.link navigate={~p"/"} class="underline">Fazer uma nova encomenda</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end
end
