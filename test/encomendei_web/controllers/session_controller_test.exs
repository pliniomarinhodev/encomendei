defmodule EncomendeiWeb.SessionControllerTest do
  use EncomendeiWeb.ConnCase

  defp login(conn, user, password) do
    post(conn, ~p"/entrar", %{"session" => %{"username" => user, "password" => password}})
  end

  test "página de entrada mostra o formulário e o caminho de volta", %{conn: conn} do
    html = conn |> get(~p"/entrar") |> html_response(200)
    assert html =~ "Área da confeiteira"
    assert html =~ ~s(name="session[password]")
    assert html =~ "Voltar ao cardápio"
  end

  test "credenciais corretas abrem o painel", %{conn: conn} do
    conn = login(conn, "admin", "admin")
    assert redirected_to(conn) == ~p"/admin/pedidos"

    conn = conn |> recycle() |> get(~p"/admin/pedidos")
    assert html_response(conn, 200) =~ "Pedidos"
  end

  test "senha errada não entra e explica o motivo", %{conn: conn} do
    conn = login(conn, "admin", "errada")
    assert redirected_to(conn) == ~p"/entrar"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "incorretos"

    assert conn |> recycle() |> get(~p"/admin/pedidos") |> redirected_to() == ~p"/entrar"
  end

  test "usuário errado também é recusado", %{conn: conn} do
    assert conn |> login("outro", "admin") |> redirected_to() == ~p"/entrar"
  end

  test "campos ausentes não derrubam a página", %{conn: conn} do
    conn = post(conn, ~p"/entrar", %{})
    assert redirected_to(conn) == ~p"/entrar"
  end

  test "quem já está logado vai direto ao painel", %{conn: conn} do
    assert conn |> admin_conn() |> get(~p"/entrar") |> redirected_to() == ~p"/admin/pedidos"
  end

  test "sair encerra a sessão", %{conn: conn} do
    conn = conn |> login("admin", "admin") |> recycle() |> delete(~p"/sair")
    assert redirected_to(conn) == ~p"/"

    assert conn |> recycle() |> get(~p"/admin/pedidos") |> redirected_to() == ~p"/entrar"
  end

  test "a API administrativa segue com Basic Auth, não com sessão", %{conn: conn} do
    assert conn |> admin_conn() |> get(~p"/api/admin/orders") |> response(401)
    assert conn |> api_admin_conn() |> get(~p"/api/admin/orders") |> json_response(200)
  end
end
