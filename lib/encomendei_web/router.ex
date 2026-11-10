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

  pipeline :admin do
    plug :admin_auth
  end

  defp admin_auth(conn, _opts) do
    creds = Application.fetch_env!(:encomendei, :admin_auth)
    Plug.BasicAuth.basic_auth(conn, creds)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EncomendeiWeb do
    pipe_through :browser

    live "/", StoreLive
    live "/pedido/:id", OrderLive.Show
  end

  scope "/admin", EncomendeiWeb do
    pipe_through [:browser, :admin]

    live "/pedidos", Admin.OrdersLive
    live "/produtos", ProductLive.Index, :index
    live "/produtos/new", ProductLive.Form, :new
    live "/produtos/:id", ProductLive.Show, :show
    live "/produtos/:id/edit", ProductLive.Form, :edit
  end

  scope "/api", EncomendeiWeb.API do
    pipe_through :api

    get "/products", ProductController, :index
    post "/orders", OrderController, :create
    get "/orders/:id", OrderController, :show
  end

  scope "/api/admin", EncomendeiWeb.API do
    pipe_through [:api, :admin]

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
