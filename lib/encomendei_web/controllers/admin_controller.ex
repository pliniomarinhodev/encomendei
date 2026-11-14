defmodule EncomendeiWeb.AdminController do
  use EncomendeiWeb, :controller

  @doc "`/admin` leva direto ao painel de pedidos."
  def index(conn, _params), do: redirect(conn, to: ~p"/admin/pedidos")
end
