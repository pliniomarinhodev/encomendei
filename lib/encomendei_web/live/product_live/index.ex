defmodule EncomendeiWeb.ProductLive.Index do
  use EncomendeiWeb, :live_view

  alias Encomendei.Catalog
  import EncomendeiWeb.Format

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "Produtos") |> stream(:products, Catalog.list_products())}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)

    case Catalog.update_product(product, %{available: !product.available}) do
      {:ok, updated} ->
        state = if updated.available, do: "disponível", else: "indisponível"

        {:noreply,
         socket
         |> stream_insert(:products, updated)
         |> put_flash(:info, "“#{updated.name}” agora está #{state}.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Não foi possível alterar a disponibilidade.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    product = Catalog.get_product!(id)

    case Catalog.delete_product(product) do
      {:ok, _product} ->
        {:noreply, stream_delete(socket, :products, product)}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "“#{product.name}” já foi vendido e não pode ser excluído. Marque como indisponível."
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} nav={:admin} active={:products}>
      <.header>
        Produtos
        <:actions>
          <.button variant="primary" navigate={~p"/admin/produtos/new"}>
            <.icon name="hero-plus" /> Novo produto
          </.button>
        </:actions>
      </.header>

      <.table
        id="products"
        rows={@streams.products}
        class="table table-sm"
        row_click={fn {_id, product} -> JS.navigate(~p"/admin/produtos/#{product}") end}
      >
        <:col :let={{_id, product}} label="Nome">
          <div class="flex items-center gap-3">
            <img
              :if={Encomendei.Catalog.Product.image_url?(product.image_url)}
              src={product.image_url}
              alt=""
              loading="lazy"
              class="size-10 shrink-0 rounded object-cover"
              onerror="this.style.display='none'"
            />
            <span>{product.name}</span>
          </div>
        </:col>
        <:col :let={{_id, product}} label="Descrição" class="hidden md:table-cell">
          {product.description}
        </:col>
        <:col :let={{_id, product}} label="Preço">
          <span class="tabular-nums">{money(product.price_cents)}</span>
        </:col>
        <:col :let={{_id, product}} label="Situação">
          <span :if={product.available} class="badge badge-soft badge-success badge-sm">Disponível</span>
          <span :if={!product.available} class="badge badge-soft badge-sm">Indisponível</span>
        </:col>
        <:action :let={{_id, product}}>
          <button
            type="button"
            phx-click="toggle"
            phx-value-id={product.id}
            class="btn btn-sm btn-soft whitespace-nowrap"
          >
            {if product.available, do: "Marcar indisponível", else: "Marcar disponível"}
          </button>
        </:action>
        <:action :let={{_id, product}}>
          <div class="sr-only">
            <.link navigate={~p"/admin/produtos/#{product}"}>Ver</.link>
          </div>
          <.link navigate={~p"/admin/produtos/#{product}/edit"} class="underline">Editar</.link>
        </:action>
        <:action :let={{id, product}}>
          <.link
            phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
            data-confirm="Excluir este produto?"
            class="text-base-content/70 underline hover:text-error"
          >
            Excluir
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end
end
