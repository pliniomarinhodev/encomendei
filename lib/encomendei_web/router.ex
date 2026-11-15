defmodule EncomendeiWeb.Router do
  use EncomendeiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EncomendeiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :require_admin do
    plug :require_admin_session
  end

  defp require_admin_session(conn, opts), do: EncomendeiWeb.AdminAuth.require_admin(conn, opts)

  # A API administrativa continua com Basic Auth, o padrão para clientes de API
  pipeline :api_admin do
    plug :admin_auth
  end

  defp admin_auth(conn, _opts) do
    creds = Application.fetch_env!(:encomendei, :admin_auth)
    Plug.BasicAuth.basic_auth(conn, creds)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Fotos enviadas pela confeiteira: públicas, sem sessão (o cardápio é aberto)
  scope "/", EncomendeiWeb do
    get "/imagens/produtos/:id", ProductImageController, :show
  end

  scope "/", EncomendeiWeb do
    pipe_through :browser

    live "/", StoreLive
    live "/acompanhar", TrackLive
    live "/pedido/:id", OrderLive.Show

    get "/entrar", SessionController, :new
    post "/entrar", SessionController, :create
    delete "/sair", SessionController, :delete
  end

  scope "/admin", EncomendeiWeb do
    pipe_through [:browser, :require_admin]

    get "/", AdminController, :index
    get "/relatorios/pedidos.csv", ReportController, :orders_csv

    live_session :admin, on_mount: {EncomendeiWeb.AdminAuth, :require_admin} do
      live "/pedidos", Admin.OrdersLive
      live "/relatorios", Admin.ReportsLive
      live "/produtos", ProductLive.Index, :index
      live "/produtos/new", ProductLive.Form, :new
      live "/produtos/:id", ProductLive.Show, :show
      live "/produtos/:id/edit", ProductLive.Form, :edit
    end
  end

  scope "/api", EncomendeiWeb.API do
    pipe_through :api

    get "/products", ProductController, :index
    post "/orders", OrderController, :create
    get "/orders/:id", OrderController, :show
  end

  scope "/api/admin", EncomendeiWeb.API do
    pipe_through [:api, :api_admin]

    get "/orders", OrderController, :index
    patch "/orders/:id/status", OrderController, :update_status
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:encomendei, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EncomendeiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
