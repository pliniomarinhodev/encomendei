defmodule EncomendeiWeb.ProductLive.Show do
  use EncomendeiWeb, :live_view

  alias Encomendei.Catalog
  import EncomendeiWeb.Format, only: [money: 1]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, page_title: "Produto", product: Catalog.get_product!(id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} nav={:admin} active={:products}>
      <.header>
        {@product.name}
        <:actions>
          <.button navigate={~p"/admin/produtos"} variant="ghost" aria-label="Voltar para produtos">
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/admin/produtos/#{@product}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Editar
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item :if={Encomendei.Catalog.Product.image_src(@product)} title="Foto">
          <img
            src={Encomendei.Catalog.Product.image_src(@product)}
            alt=""
            class="h-32 w-32 rounded border border-base-300 object-cover"
            onerror="this.style.display='none'"
          />
        </:item>
        <:item title="Descrição">{@product.description}</:item>
        <:item title="Preço">{money(@product.price_cents)}</:item>
        <:item title="Situação">
          {if @product.available, do: "Disponível", else: "Indisponível"}
        </:item>
      </.list>
    </Layouts.app>
    """
  end
end
