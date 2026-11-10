defmodule Encomendei.Repo do
  use Ecto.Repo,
    otp_app: :encomendei,
    adapter: Ecto.Adapters.Postgres
end
