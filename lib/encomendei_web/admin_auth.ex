defmodule EncomendeiWeb.AdminAuth do
  @moduledoc """
  Autenticação da confeiteira por sessão (página de login), no lugar do pop-up
  de senha do navegador.

  O usuário e a senha vêm da configuração `:admin_auth` (variáveis `ADMIN_USER`
  e `ADMIN_PASSWORD` em produção). A sessão fica num cookie assinado e expira
  depois de #{12} horas. A API administrativa (`/api/admin`) continua usando
  Basic Auth, que é o padrão para clientes de API.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  use Phoenix.VerifiedRoutes, endpoint: EncomendeiWeb.Endpoint, router: EncomendeiWeb.Router

  @session_seconds 12 * 3600

  @doc "Confere usuário e senha em tempo constante."
  @spec valid_credentials?(term(), term()) :: boolean()
  def valid_credentials?(user, password) when is_binary(user) and is_binary(password) do
    creds = Application.fetch_env!(:encomendei, :admin_auth)

    user_ok = Plug.Crypto.secure_compare(user, Keyword.fetch!(creds, :username))
    password_ok = Plug.Crypto.secure_compare(password, Keyword.fetch!(creds, :password))
    user_ok and password_ok
  end

  def valid_credentials?(_user, _password), do: false

  @doc "Abre a sessão da confeiteira, renovando o identificador contra fixação de sessão."
  @spec log_in(Plug.Conn.t()) :: Plug.Conn.t()
  def log_in(conn) do
    conn |> configure_session(renew: true) |> put_session(:admin_at, System.system_time(:second))
  end

  @spec log_out(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out(conn), do: configure_session(conn, drop: true)

  @doc "Diz se a sessão (mapa de strings) é de uma confeiteira com login ainda válido."
  @spec admin?(map() | nil) :: boolean()
  def admin?(%{"admin_at" => at}) when is_integer(at),
    do: System.system_time(:second) - at < @session_seconds

  def admin?(_session), do: false

  @doc "Plug: só deixa passar quem fez login; os demais vão para a página de entrada."
  def require_admin(conn, _opts) do
    if admin?(get_session(conn)) do
      conn
    else
      conn
      |> put_flash(:error, "Entre para acessar a área da confeiteira.")
      |> redirect(to: ~p"/entrar")
      |> halt()
    end
  end

  @doc "Hook de LiveView com a mesma regra do plug, também válida em reconexões."
  def on_mount(:require_admin, _params, session, socket) do
    if admin?(session) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/entrar")}
    end
  end
end
