defmodule EncomendeiWeb.SessionController do
  use EncomendeiWeb, :controller

  alias EncomendeiWeb.AdminAuth

  def new(conn, _params) do
    if AdminAuth.admin?(get_session(conn)) do
      redirect(conn, to: ~p"/admin/pedidos")
    else
      render(conn, :new, page_title: "Entrar")
    end
  end

  def create(conn, %{"session" => %{"username" => user, "password" => password}}) do
    if AdminAuth.valid_credentials?(user, password) do
      conn
      |> AdminAuth.log_in()
      |> redirect(to: ~p"/admin/pedidos")
    else
      # Pausa curta para desencorajar tentativas em série
      Process.sleep(400)

      conn
      |> put_flash(:error, "Usuário ou senha incorretos.")
      |> redirect(to: ~p"/entrar")
    end
  end

  def create(conn, _params) do
    conn |> put_flash(:error, "Informe usuário e senha.") |> redirect(to: ~p"/entrar")
  end

  def delete(conn, _params) do
    conn |> AdminAuth.log_out() |> redirect(to: ~p"/")
  end
end
