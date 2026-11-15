defmodule EncomendeiWeb.StoreLive do
  @moduledoc "Cardápio público: o cliente monta o carrinho e faz a encomenda."
  use EncomendeiWeb, :live_view

  alias Encomendei.{Catalog, Sales}
  alias Encomendei.Catalog.Product
  alias EncomendeiWeb.Cart
  import EncomendeiWeb.Format

  @blank_checkout %{
    "name" => "",
    "phone" => "",
    "delivery_mode" => "asap",
    "delivery_at" => "",
    "notes" => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Cardápio",
       products: Catalog.list_available_products(),
       cart: Cart.new(),
       error: nil,
       form: checkout_form(@blank_checkout, [])
     )}
  end

  @impl true
  def handle_event("add", %{"id" => id}, socket) do
    {:noreply, update(socket, :cart, &Cart.add(&1, id))}
  end

  def handle_event("remove", %{"id" => id}, socket) do
    {:noreply, update(socket, :cart, &Cart.remove(&1, id))}
  end

  def handle_event("validate", %{"checkout" => params}, socket) do
    %{params: previous, errors: errors} = socket.assigns.form

    untouched =
      Enum.filter(errors, fn {field, _} ->
        params[to_string(field)] == previous[to_string(field)]
      end)

    {:noreply, assign(socket, form: checkout_form(params, untouched), error: nil)}
  end

  def handle_event("submit", %{"checkout" => params}, socket) do
    case Sales.place_order(order_attrs(params, socket.assigns.cart)) do
      {:ok, order} ->
        {:noreply, push_navigate(socket, to: ~p"/pedido/#{order.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: checkout_form(params, changeset.errors), error: nil)}

      {:error, reason} ->
        {:noreply, assign(socket, form: checkout_form(params, []), error: error_message(reason))}
    end
  end

  defp checkout_form(params, errors), do: to_form(params, as: :checkout, errors: errors)

  defp order_attrs(params, cart) do
    %{
      "name" => params["name"],
      "phone" => params["phone"],
      "notes" => params["notes"],
      "delivery_at" => scheduled_at(params),
      "items" => Cart.to_items(cart)
    }
  end

  # Só há data quando o cliente escolheu agendar; senão é "o mais rápido possível".
  defp scheduled_at(%{"delivery_mode" => "scheduled"} = params),
    do: parse_local(params["delivery_at"])

  defp scheduled_at(_params), do: nil

  defp item_word(1), do: "item"
  defp item_word(_), do: "itens"

  defp error_message(:empty_cart), do: "Adicione ao menos um item ao carrinho."

  defp error_message(:unavailable_product),
    do: "Algum item não está mais disponível. Atualize a página."

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active={:menu}>
      <div class="grid gap-10 lg:grid-cols-[minmax(0,1fr)_22rem] lg:items-start">
        <section aria-labelledby="titulo-cardapio">
          <.header>
            <span id="titulo-cardapio">Cardápio</span>
            <:subtitle>Escolha os produtos, informe a entrega e envie sua encomenda.</:subtitle>
          </.header>

          <p :if={@products == []} class="py-8 text-base-content/70">
            Nenhum produto disponível no momento.
          </p>

          <ul class="divide-y divide-base-300 border-y border-base-300" aria-label="Produtos">
            <li :for={product <- @products} class="flex flex-wrap items-center gap-x-4 gap-y-3 py-4">
              <img
                :if={Product.image_src(product)}
                src={Product.image_src(product)}
                alt=""
                loading="lazy"
                class="size-20 shrink-0 rounded object-cover sm:size-24"
                onerror="this.style.display='none'"
              />
              <div class={[
                "min-w-0 sm:flex-1 sm:basis-0",
                (Product.image_src(product) && "flex-1 basis-[calc(100%-6rem)]") ||
                  "basis-full"
              ]}>
                <h2 class="font-semibold">{product.name}</h2>
                <p :if={product.description} class="text-sm text-base-content/70">
                  {product.description}
                </p>
              </div>
              <p class="font-semibold tabular-nums sm:w-24 sm:text-right">
                {money(product.price_cents)}
              </p>
              <div class="ml-auto flex items-center gap-1 sm:ml-0">
                <.button
                  type="button"
                  class="btn btn-outline btn-square min-h-11 min-w-11"
                  phx-click="remove"
                  phx-value-id={product.id}
                  aria-label={"Remover um #{product.name}"}
                  disabled={Cart.quantity(@cart, product) == 0}
                >
                  −
                </.button>
                <span
                  class="w-8 text-center text-lg tabular-nums"
                  aria-live="polite"
                  aria-label={"Quantidade de #{product.name}"}
                >
                  {Cart.quantity(@cart, product)}
                </span>
                <.button
                  type="button"
                  class="btn btn-primary btn-square min-h-11 min-w-11"
                  phx-click="add"
                  phx-value-id={product.id}
                  aria-label={"Adicionar um #{product.name}"}
                >
                  +
                </.button>
              </div>
            </li>
          </ul>
        </section>

        <aside
          aria-labelledby="titulo-pedido"
          class="scroll-mt-4 space-y-4 border border-base-300 bg-base-200 p-5 lg:sticky lg:top-6"
        >
          <h2 id="titulo-pedido" class="text-lg font-semibold">Seu pedido</h2>

          <ul :if={!Cart.empty?(@cart)} class="space-y-1 text-sm" aria-label="Itens do carrinho">
            <li :for={line <- Cart.lines(@cart, @products)} class="flex justify-between gap-2">
              <span>{line.quantity}× {line.product.name}</span>
              <span class="tabular-nums">{money(line.subtotal_cents)}</span>
            </li>
          </ul>
          <p :if={Cart.empty?(@cart)} class="text-sm text-base-content/70">O carrinho está vazio.</p>

          <p
            class="flex justify-between border-t border-base-300 pt-3 font-semibold"
            aria-live="polite"
          >
            <span>Total</span>
            <span class="tabular-nums">{money(Cart.total_cents(@cart, @products))}</span>
          </p>

          <.form for={@form} id="checkout-form" phx-change="validate" phx-submit="submit">
            <.input field={@form[:name]} label="Nome" required autocomplete="name" />
            <.input
              field={@form[:phone]}
              type="tel"
              label="Telefone com DDD (WhatsApp)"
              required
              autocomplete="tel"
            />
            <fieldset class="mb-4">
              <legend class="label mb-1">Previsão de entrega</legend>
              <label class="flex items-center gap-2 py-1">
                <input
                  type="radio"
                  name="checkout[delivery_mode]"
                  value="asap"
                  checked={@form[:delivery_mode].value != "scheduled"}
                  class="radio radio-sm"
                /> Primeira data disponível (previsão confirmada pela confeitaria)
              </label>
              <label class="flex items-center gap-2 py-1">
                <input
                  type="radio"
                  name="checkout[delivery_mode]"
                  value="scheduled"
                  checked={@form[:delivery_mode].value == "scheduled"}
                  class="radio radio-sm"
                /> Agendar entrega
              </label>
            </fieldset>
            <.input
              :if={@form[:delivery_mode].value == "scheduled"}
              field={@form[:delivery_at]}
              type="datetime-local"
              label="Data e hora da entrega"
              required
            />
            <.input field={@form[:notes]} type="textarea" label="Observações (opcional)" />

            <p :if={@error} role="alert" class="mb-2 text-sm text-error">{@error}</p>
            <.button
              type="submit"
              variant="primary"
              class="btn btn-primary w-full"
              disabled={Cart.empty?(@cart)}
            >
              Enviar encomenda
            </.button>
          </.form>
        </aside>
      </div>

      <div
        :if={!Cart.empty?(@cart)}
        id="cart-bar"
        class="fixed inset-x-0 bottom-0 z-40 border-t border-base-300 bg-base-100 p-3 lg:hidden"
      >
        <div class="mx-auto flex max-w-6xl items-center justify-between gap-3">
          <p>
            <span class="font-semibold">{Cart.count(@cart)} {item_word(Cart.count(@cart))}</span>
            ·
            <span class="font-semibold tabular-nums">{money(Cart.total_cents(@cart, @products))}</span>
          </p>
          <a href="#titulo-pedido" class="btn btn-primary">Finalizar pedido</a>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
