defmodule EncomendeiWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use EncomendeiWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :nav, :atom, values: [:public, :admin], default: :public
  attr :active, :atom, default: nil, doc: "aba ativa do painel"

  slot :inner_block, required: true

  def app(assigns) do
    shop = Encomendei.Shop.get_settings()
    assigns = assign(assigns, shop: shop, logo_src: Encomendei.Shop.logo_src(shop))

    ~H"""
    <a
      href="#conteudo"
      class="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:bg-base-100 focus:p-3"
    >
      Ir para o conteúdo
    </a>

    <header class="border-b border-base-300 bg-base-100">
      <div class={[
        "mx-auto flex flex-wrap items-center gap-x-6 gap-y-2 px-4 py-3 sm:px-6",
        content_width(@nav)
      ]}>
        <.link
          navigate={home_path(@nav)}
          class="flex items-center gap-2 text-lg font-bold tracking-tight text-primary"
          aria-label={"#{@shop.name}, página inicial"}
        >
          <img
            :if={@logo_src}
            src={@logo_src}
            alt=""
            class="h-9 max-w-28 object-contain"
          />
          {@shop.name}
        </.link>

        <nav
          :if={@nav == :admin}
          aria-label="Painel"
          class="order-last -mx-1 flex w-full gap-1 overflow-x-auto sm:order-none sm:mx-0 sm:w-auto sm:flex-1"
        >
          <.link
            :for={{key, label, path} <- admin_tabs()}
            navigate={path}
            aria-current={@active == key && "page"}
            class={[
              "whitespace-nowrap rounded px-3 py-2 text-sm font-medium sm:py-1.5",
              @active == key && "bg-base-200",
              @active != key && "text-base-content/70 hover:bg-base-200"
            ]}
          >
            {label}
          </.link>
        </nav>

        <nav
          :if={@nav == :public}
          aria-label="Principal"
          class="order-last -mx-1 flex w-full gap-1 overflow-x-auto sm:order-none sm:mx-0 sm:w-auto sm:flex-1"
        >
          <.link
            :for={{key, label, path} <- public_tabs()}
            navigate={path}
            aria-current={@active == key && "page"}
            class={[
              "whitespace-nowrap rounded px-3 py-2 text-sm font-medium sm:py-1.5",
              @active == key && "bg-base-200",
              @active != key && "text-base-content/70 hover:bg-base-200"
            ]}
          >
            {label}
          </.link>
        </nav>

        <div class="ml-auto flex items-center gap-3">
          <.link :if={@nav == :admin} navigate={~p"/"} class="hidden text-sm underline sm:inline">
            Ver cardápio
          </.link>
          <.link
            :if={@nav == :admin}
            href={~p"/sair"}
            method="delete"
            class="btn btn-ghost btn-sm"
          >
            Sair
          </.link>
          <.theme_toggle />
        </div>
      </div>
    </header>

    <main id="conteudo" class="px-4 py-8 pb-24 sm:px-6 lg:pb-8">
      <div class={["mx-auto space-y-6", content_width(@nav)]}>
        {render_slot(@inner_block)}
      </div>
    </main>

    <footer
      :if={@nav == :public and @active != :login}
      class="px-4 pb-8 text-center text-sm text-base-content/75"
    >
      <.link navigate={~p"/entrar"} class="underline">Área da confeiteira</.link>
    </footer>

    <.flash_group flash={@flash} />
    """
  end

  defp content_width(:admin), do: "max-w-7xl"
  defp content_width(:public), do: "max-w-6xl"

  defp home_path(:admin), do: ~p"/admin/pedidos"
  defp home_path(:public), do: ~p"/"

  defp public_tabs do
    [
      {:menu, "Cardápio", ~p"/"},
      {:track, "Acompanhar pedido", ~p"/acompanhar"}
    ]
  end

  defp admin_tabs do
    [
      {:orders, "Pedidos", ~p"/admin/pedidos"},
      {:products, "Produtos", ~p"/admin/produtos"},
      {:reports, "Relatórios", ~p"/admin/relatorios"},
      {:shop, "Loja", ~p"/admin/loja"}
    ]
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="Tema do sistema"
        title="Tema do sistema"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Tema claro"
        title="Tema claro"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Tema escuro"
        title="Tema escuro"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
