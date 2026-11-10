defmodule EncomendeiWeb.StoreLive do
  @moduledoc "Cardápio público: o cliente monta o carrinho e faz a encomenda."
  use EncomendeiWeb, :live_view

  alias Encomendei.{Catalog, Sales}
  import EncomendeiWeb.Format

  @impl true
  def mount(_params, _session, socket) do
    products = Catalog.list_products() |> Enum.filter(& &1.available)

    {:ok,
     socket
     |> assign(page_title: "Cardápio", products: products, cart: %{}, error: nil)
     |> assign(
       form:
         to_form(%{"name" => "", "phone" => "", "delivery_at" => "", "notes" => ""},
           as: :checkout
         )
     )}
  end

  @impl true
  def handle_event("add", %{"id" => id}, socket) do
    {:noreply, update(socket, :cart, &Map.update(&1, id, 1, fn q -> min(q + 1, 99) end))}
  end

  def handle_event("remove", %{"id" => id}, socket) do
    cart =
      case Map.get(socket.assigns.cart, id) do
        nil -> socket.assigns.cart
        1 -> Map.delete(socket.assigns.cart, id)
        q -> Map.put(socket.assigns.cart, id, q - 1)
      end

    {:noreply, assign(socket, cart: cart)}
  end

  def handle_event("validate", %{"checkout" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: :checkout), error: nil)}
  end

  def handle_event("submit", %{"checkout" => params}, socket) do
    attrs = %{
      "name" => params["name"],
      "phone" => params["phone"],
      "notes" => params["notes"],
      "delivery_at" => parse_local(params["delivery_at"]),
      "items" => for({id, q} <- socket.assigns.cart, do: %{"product_id" => id, "quantity" => q})
    }

    case Sales.place_order(attrs) do
      {:ok, order} ->
        {:noreply, push_navigate(socket, to: ~p"/pedido/#{order.id}")}

      {:error, reason} ->
        {:noreply,
         assign(socket, form: to_form(params, as: :checkout), error: error_message(reason))}
    end
  end

  defp error_message(:empty_cart), do: "Adicione ao menos um item ao carrinho."

  defp error_message(:unavailable_product),
    do: "Algum item não está mais disponível. Atualize a página."

  defp error_message(%Ecto.Changeset{} = cs) do
    cs
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map_join(" ", fn {field, msgs} ->
      "#{field_label(field)}: #{Enum.join(msgs, ", ")}."
    end)
  end

  defp error_message(_), do: "Não foi possível registrar o pedido. Tente novamente."

  defp field_label(:name), do: "Nome"
  defp field_label(:phone), do: "Telefone"
  defp field_label(:delivery_at), do: "Data de entrega"
  defp field_label(other), do: to_string(other)

  defp qty(cart, product), do: Map.get(cart, product.id, 0)

  defp total(cart, products) do
    Enum.sum(for p <- products, do: qty(cart, p) * p.price_cents)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-3xl font-bold">Cardápio</h1>
      <p class="text-base-content/70">
        Escolha os produtos, informe a data de entrega e envie sua encomenda.
      </p>

      <p :if={@products == []} class="py-8 text-center">Nenhum produto disponível no momento.</p>

      <ul class="grid gap-4 sm:grid-cols-2" aria-label="Produtos">
        <li :for={product <- @products} class="card bg-base-200 p-4 space-y-2">
          <h2 class="text-lg font-semibold">{product.name}</h2>
          <p :if={product.description} class="text-sm">{product.description}</p>
          <p class="font-bold">{money(product.price_cents)}</p>
          <div class="flex items-center gap-2">
            <button
              type="button"
              class="btn btn-sm"
              phx-click="remove"
              phx-value-id={product.id}
              aria-label={"Remover um #{product.name}"}
              disabled={qty(@cart, product) == 0}
            >−</button>
            <span
              class="w-8 text-center"
              aria-live="polite"
              aria-label={"Quantidade de #{product.name}"}
            >{qty(@cart, product)}</span>
            <button
              type="button"
              class="btn btn-sm btn-primary"
              phx-click="add"
              phx-value-id={product.id}
              aria-label={"Adicionar um #{product.name}"}
            >+</button>
          </div>
        </li>
      </ul>

      <section aria-labelledby="titulo-pedido" class="card bg-base-200 p-4 space-y-3">
        <h2 id="titulo-pedido" class="text-xl font-semibold">Seu pedido</h2>
        <p aria-live="polite" class="font-bold">Total: {money(total(@cart, @products))}</p>

        <.form
          for={@form}
          id="checkout-form"
          phx-change="validate"
          phx-submit="submit"
          class="space-y-2"
        >
          <.input field={@form[:name]} label="Nome" required autocomplete="name" />
          <.input
            field={@form[:phone]}
            type="tel"
            label="Telefone com DDD (WhatsApp)"
            required
            autocomplete="tel"
          />
          <.input
            field={@form[:delivery_at]}
            type="datetime-local"
            label="Data e hora da entrega"
            required
          />
          <.input field={@form[:notes]} type="textarea" label="Observações (opcional)" />

          <p :if={@error} role="alert" class="text-error">{@error}</p>
          <button type="submit" class="btn btn-primary" disabled={@cart == %{}}>Enviar encomenda</button>
        </.form>
      </section>
    </Layouts.app>
    """
  end
end
