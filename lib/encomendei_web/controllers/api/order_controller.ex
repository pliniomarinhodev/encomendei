defmodule EncomendeiWeb.API.OrderController do
  use EncomendeiWeb, :controller
  alias Encomendei.Sales
  alias EncomendeiWeb.API.JSON, as: J

  @statuses Map.new(Sales.Order.statuses(), &{Atom.to_string(&1), &1})

  # Rota pública: cria pedido
  def create(conn, params) do
    with {:ok, delivery_at} <- parse_datetime(params["delivery_at"]),
         {:ok, order} <- Sales.place_order(Map.put(params, "delivery_at", delivery_at)) do
      conn |> put_status(:created) |> json(%{data: J.order(order)})
    else
      {:error, :bad_datetime} ->
        unprocessable(conn, %{
          delivery_at: ["use o formato ISO 8601, ex.: 2026-11-20T14:00:00-03:00"]
        })

      {:error, :empty_cart} ->
        unprocessable(conn, %{items: ["adicione ao menos um item"]})

      {:error, :unavailable_product} ->
        unprocessable(conn, %{items: ["algum produto não existe ou não está disponível"]})

      {:error, %Ecto.Changeset{} = cs} ->
        unprocessable(conn, J.changeset_errors(cs))
    end
  end

  # Rota pública: consulta pelo id (que funciona como "senha" do pedido)
  def show(conn, %{"id" => id}) do
    case fetch(id) do
      nil -> not_found(conn)
      order -> json(conn, %{data: J.order(order)})
    end
  end

  # Rotas administrativas
  def index(conn, params) do
    opts =
      case Map.get(@statuses, params["status"]) do
        nil -> []
        status -> [status: status]
      end

    json(conn, %{data: Sales.list_orders(opts) |> Enum.map(&J.order/1)})
  end

  def update_status(conn, %{"id" => id, "status" => status}) do
    with %{} = order <- fetch(id),
         {:ok, new} <- Map.fetch(@statuses, status) |> ok_or(:bad_status),
         {:ok, _} <- Sales.update_status(order, new) do
      json(conn, %{data: J.order(Sales.get_order!(id))})
    else
      nil -> not_found(conn)
      {:error, :bad_status} -> unprocessable(conn, %{status: ["status inválido"]})
      {:error, :invalid_transition} -> unprocessable(conn, %{status: ["transição não permitida"]})
    end
  end

  def update_status(conn, _), do: unprocessable(conn, %{status: ["é obrigatório"]})

  defp ok_or({:ok, _} = ok, _), do: ok
  defp ok_or(:error, reason), do: {:error, reason}

  defp parse_datetime(nil), do: {:error, :bad_datetime}

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> {:ok, DateTime.truncate(dt, :second)}
      _ -> {:error, :bad_datetime}
    end
  end

  defp parse_datetime(_), do: {:error, :bad_datetime}

  defp fetch(id) do
    Sales.get_order!(id)
  rescue
    _ -> nil
  end

  defp not_found(conn),
    do: conn |> put_status(:not_found) |> json(%{errors: %{detail: "não encontrado"}})

  defp unprocessable(conn, errors),
    do: conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
end
