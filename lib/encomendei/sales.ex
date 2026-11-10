defmodule Encomendei.Sales do
  @moduledoc """
  Contexto de vendas: clientes, pedidos e fila de produção.

  O preço de cada item é sempre lido do catálogo no servidor; o valor enviado
  pelo cliente nunca é usado.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Encomendei.Repo
  alias Encomendei.Catalog.Product
  alias Encomendei.Sales.{Customer, Order, OrderItem}

  @topic "orders"

  # Transições permitidas entre status
  @transitions %{
    pending: [:in_production, :canceled],
    in_production: [:delivered, :canceled],
    delivered: [],
    canceled: []
  }

  def subscribe, do: Phoenix.PubSub.subscribe(Encomendei.PubSub, @topic)

  defp broadcast({:ok, order} = result, event) do
    Phoenix.PubSub.broadcast(Encomendei.PubSub, @topic, {event, order.id})
    result
  end

  defp broadcast(error, _event), do: error

  ## Pedidos

  @doc """
  Lista pedidos com cliente e itens. Aceita `:status` (atom ou lista de atoms).
  Ordena pela data de entrega.
  """
  def list_orders(opts \\ []) do
    Order
    |> filter_status(opts[:status])
    |> order_by([o], asc: o.delivery_at)
    |> preload([:customer, items: :product])
    |> Repo.all()
  end

  defp filter_status(query, nil), do: query
  defp filter_status(query, status), do: where(query, [o], o.status in ^List.wrap(status))

  def get_order!(id), do: Order |> preload([:customer, items: :product]) |> Repo.get!(id)

  @doc """
  Registra um pedido a partir do formulário público.

  Espera `%{"name", "phone", "delivery_at", "notes", "items" => [%{"product_id", "quantity"}]}`.
  """
  def place_order(attrs) do
    item_attrs = attrs |> fetch(:items) |> List.wrap() |> Enum.reject(&(qty(&1) <= 0))

    Multi.new()
    |> Multi.run(:products, fn _, _ -> load_products(item_attrs) end)
    |> Multi.run(:customer, fn _, _ -> upsert_customer(attrs) end)
    |> Multi.insert(:order, fn %{customer: customer, products: products} ->
      items = build_items(item_attrs, products)

      Order.changeset(%Order{}, %{
        customer_id: customer.id,
        delivery_at: fetch(attrs, :delivery_at),
        notes: fetch(attrs, :notes),
        total_cents: Enum.sum(for i <- items, do: i.quantity * i.unit_price_cents)
      })
    end)
    |> Multi.run(:items, fn repo, %{order: order, products: products} ->
      rows =
        for i <- build_items(item_attrs, products) do
          %OrderItem{} |> OrderItem.changeset(Map.put(i, :order_id, order.id)) |> repo.insert!()
        end

      {:ok, rows}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{order: order}} -> broadcast({:ok, get_order!(order.id)}, :order_created)
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  defp load_products([]), do: {:error, :empty_cart}

  defp load_products(item_attrs) do
    ids = Enum.map(item_attrs, &fetch(&1, :product_id))
    products = Repo.all(from p in Product, where: p.id in ^ids and p.available == true)

    if length(products) == length(Enum.uniq(ids)),
      do: {:ok, Map.new(products, &{&1.id, &1})},
      else: {:error, :unavailable_product}
  end

  defp build_items(item_attrs, products) do
    for i <- item_attrs do
      product = Map.fetch!(products, fetch(i, :product_id))
      %{product_id: product.id, quantity: qty(i), unit_price_cents: product.price_cents}
    end
  end

  defp upsert_customer(attrs) do
    changeset = Customer.changeset(%Customer{}, %{name: fetch(attrs, :name), phone: fetch(attrs, :phone)})

    case Ecto.Changeset.apply_action(changeset, :validate) do
      {:ok, %{phone: phone, name: name}} ->
        case Repo.get_by(Customer, phone: phone) do
          nil -> Repo.insert(changeset)
          customer -> customer |> Customer.changeset(%{name: name}) |> Repo.update()
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc "Status que o pedido pode assumir a partir do atual."
  def next_statuses(%Order{status: status}), do: Map.fetch!(@transitions, status)

  @doc "Muda o status respeitando o fluxo pendente → em produção → entregue."
  def update_status(%Order{} = order, new_status) when is_atom(new_status) do
    if new_status in next_statuses(order) do
      order
      |> Order.status_changeset(new_status)
      |> Repo.update()
      |> broadcast(:order_updated)
    else
      {:error, :invalid_transition}
    end
  end

  ## Clientes

  def list_customers, do: Repo.all(from c in Customer, order_by: c.name)
  def get_customer!(id), do: Repo.get!(Customer, id)

  # Aceita chaves atom ou string vindas de formulários e da API
  defp fetch(map, key), do: Map.get(map, key) || Map.get(map, to_string(key))

  defp qty(item) do
    case fetch(item, :quantity) do
      n when is_integer(n) -> n
      s when is_binary(s) -> (Integer.parse(s) |> elem_or_zero())
      _ -> 0
    end
  end

  defp elem_or_zero({n, _}), do: n
  defp elem_or_zero(:error), do: 0
end
