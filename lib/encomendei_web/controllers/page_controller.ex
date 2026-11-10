defmodule EncomendeiWeb.PageController do
  use EncomendeiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
