defmodule Encomendei.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EncomendeiWeb.Telemetry,
      Encomendei.Repo,
      {DNSCluster, query: Application.get_env(:encomendei, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Encomendei.PubSub},
      # Start a worker by calling: Encomendei.Worker.start_link(arg)
      # {Encomendei.Worker, arg},
      # Start to serve requests, typically the last entry
      EncomendeiWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Encomendei.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EncomendeiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
