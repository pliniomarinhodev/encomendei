defmodule EncomendeiWeb.ProductLive.Form do
  use EncomendeiWeb, :live_view

  alias Encomendei.Catalog
  alias Encomendei.Catalog.Product
  import EncomendeiWeb.Format, only: [price_input: 1]

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_other), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Catalog.get_product!(id)
    assign_form(socket, "Editar produto", product, %{"price" => price_input(product.price_cents)})
  end

  defp apply_action(socket, :new, _params) do
    assign_form(socket, "Novo produto", %Product{available: true}, %{})
  end

  defp assign_form(socket, title, product, params) do
    socket
    |> assign(page_title: title, product: product)
    |> assign(:form, to_form(Catalog.change_product(product, params)))
  end

  @impl true
  def handle_event("validate", %{"product" => params}, socket) do
    changeset = Catalog.change_product(socket.assigns.product, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"product" => params}, socket) do
    case persist(socket.assigns.live_action, socket.assigns.product, params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Produto salvo.")
         |> push_navigate(to: return_path(socket.assigns.return_to, product))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp persist(:edit, product, params), do: Catalog.update_product(product, params)
  defp persist(:new, _product, params), do: Catalog.create_product(params)

  defp return_path("index", _product), do: ~p"/admin/produtos"
  defp return_path("show", product), do: ~p"/admin/produtos/#{product}"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} nav={:admin} active={:products}>
      <div class="max-w-xl">
        <.header>
          {@page_title}
          <:subtitle>O preço é em reais, por exemplo 45,00.</:subtitle>
        </.header>

        <.form for={@form} id="product-form" phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} type="text" label="Nome" required />
          <.input field={@form[:description]} type="textarea" label="Descrição" />
          <.input field={@form[:price]} type="text" label="Preço (R$)" inputmode="decimal" required />
          <.input
            field={@form[:image_url]}
            type="url"
            label="Link da foto (opcional)"
            placeholder="https://..."
          />
          <p class="-mt-2 mb-4 text-xs text-base-content/70">
            Cole o endereço direto de uma imagem (termina em .jpg, .png ou .webp). Se o link sair do ar, o produto aparece sem foto.
          </p>
          <img
            :if={Product.image_url?(@form[:image_url].value)}
            src={@form[:image_url].value}
            alt="Pré-visualização da foto do produto"
            class="mb-4 h-32 w-32 rounded border border-base-300 object-cover"
            onerror="this.style.display='none'"
          />
          <.input field={@form[:available]} type="checkbox" label="Disponível para encomenda" />
          <footer class="flex gap-2 pt-2">
            <.button type="submit" variant="primary" phx-disable-with="Salvando...">Salvar</.button>
            <.button navigate={return_path(@return_to, @product)} variant="ghost">Cancelar</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
