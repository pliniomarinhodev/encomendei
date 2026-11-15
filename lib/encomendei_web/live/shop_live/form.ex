defmodule EncomendeiWeb.ShopLive.Form do
  use EncomendeiWeb, :live_view

  alias Encomendei.{Images, Shop}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Loja")
     |> allow_upload(:logo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: Images.max_bytes()
     )
     |> assign_settings()}
  end

  defp assign_settings(socket) do
    settings = Shop.get_settings()

    assign(socket,
      settings: settings,
      logo_src: Shop.logo_src(settings),
      form: to_form(Shop.change_settings(settings))
    )
  end

  @impl true
  def handle_event("validate", %{"setting" => params}, socket) do
    changeset = Shop.change_settings(socket.assigns.settings, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("cancel-logo", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :logo, ref)}
  end

  def handle_event("save", %{"setting" => params}, socket) do
    if Enum.all?(socket.assigns.uploads.logo.entries, & &1.valid?) do
      case Shop.update_settings(put_logo(params, socket)) do
        {:ok, _settings} ->
          {:noreply,
           socket
           |> put_flash(:info, "Loja atualizada.")
           |> push_navigate(to: ~p"/admin/loja")}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      {:noreply, put_flash(socket, :error, "Escolha outro logo: esse não pode ser enviado.")}
    end
  end

  # O logo escolhido vira bytes para o banco; "remover" segue nos parâmetros até o changeset.
  defp put_logo(params, socket) do
    uploaded =
      consume_uploaded_entries(socket, :logo, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)

    case uploaded do
      [data] -> params |> Map.put("logo_data", data) |> Map.delete("remove_logo")
      [] -> params
    end
  end

  defp upload_error(:too_large), do: "O logo passa de 2 MB."
  defp upload_error(:not_accepted), do: "Use uma imagem JPG, PNG ou WebP."
  defp upload_error(_other), do: "Não foi possível enviar esse logo."

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} nav={:admin} active={:shop}>
      <div class="max-w-xl">
        <.header>
          Loja
          <:subtitle>
            Nome e logo que aparecem no topo do cardápio e do painel.
          </:subtitle>
        </.header>

        <.form for={@form} id="shop-form" phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} type="text" label="Nome da loja" required />

          <div class="mb-4" phx-drop-target={@uploads.logo.ref}>
            <label for={@uploads.logo.ref} class="label mb-1">Logo (opcional)</label>
            <.live_file_input upload={@uploads.logo} class="file-input file-input-sm w-full" />
            <p class="mt-1 text-xs text-base-content/70">
              JPG, PNG ou WebP, até 2 MB. Fundo transparente (PNG) fica melhor.
            </p>
            <div :for={entry <- @uploads.logo.entries} class="mt-2 flex items-center gap-3">
              <.live_img_preview
                entry={entry}
                alt="Pré-visualização do logo escolhido"
                class="h-20 max-w-48 rounded border border-base-300 bg-base-100 object-contain p-1"
              />
              <button
                type="button"
                class="btn btn-ghost btn-sm"
                phx-click="cancel-logo"
                phx-value-ref={entry.ref}
              >
                Tirar logo
              </button>
              <p :for={err <- upload_errors(@uploads.logo, entry)} class="text-sm text-error">
                {upload_error(err)}
              </p>
            </div>
            <p :for={err <- upload_errors(@uploads.logo)} class="mt-1 text-sm text-error">
              {upload_error(err)}
            </p>
            <p :for={{msg, _} <- @form[:logo_data].errors} class="mt-1 text-sm text-error">
              {msg}
            </p>
            <div :if={@logo_src} class="mt-3 flex items-center gap-3">
              <img
                src={@logo_src}
                alt="Logo atual da loja"
                class="h-20 max-w-48 rounded border border-base-300 bg-base-100 object-contain p-1"
              />
              <label class="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  name="setting[remove_logo]"
                  value="true"
                  class="checkbox checkbox-sm"
                /> Remover o logo
              </label>
            </div>
          </div>

          <footer class="flex gap-2 pt-2">
            <.button type="submit" variant="primary" phx-disable-with="Salvando...">Salvar</.button>
            <.button navigate={~p"/admin/pedidos"} variant="ghost">Voltar ao painel</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
