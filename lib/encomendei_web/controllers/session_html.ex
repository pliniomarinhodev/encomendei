defmodule EncomendeiWeb.SessionHTML do
  use EncomendeiWeb, :html

  alias EncomendeiWeb.Layouts

  def new(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active={:login}>
      <div class="mx-auto max-w-sm space-y-6 py-6">
        <.header>
          Área da confeiteira
          <:subtitle>Entre para ver os pedidos, os produtos e os relatórios.</:subtitle>
        </.header>

        <form action={~p"/entrar"} method="post" id="login-form" class="space-y-1">
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          <.input name="session[username]" label="Usuário" value="" autocomplete="username" required />
          <.input
            name="session[password]"
            type="password"
            label="Senha"
            value=""
            autocomplete="current-password"
            required
          />
          <div class="pt-2">
            <.button type="submit" variant="primary" class="btn btn-primary w-full">Entrar</.button>
          </div>
        </form>

        <p class="text-center text-sm">
          <.link navigate={~p"/"} class="underline">Voltar ao cardápio</.link>
        </p>
      </div>
    </Layouts.app>
    """
  end
end
