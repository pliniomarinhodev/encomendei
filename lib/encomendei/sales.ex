defmodule Encomendei.Sales do
  @moduledoc """
  Clientes, encomendas e fila de produção.

  Regras de negócio:

    * o preço de cada item vem sempre do catálogo, lido no servidor; qualquer
      valor enviado pelo cliente é ignorado;
    * o preço é gravado no item, então mudar o catálogo depois não altera
      encomendas já feitas;
    * só produtos disponíveis podem ser encomendados, e a entrega deve estar
      no futuro;
    * a encomenda, o cliente e os itens são gravados juntos ou não são
      gravados;
    * o status avança de `:pending` para `:in_production` e depois
      `:delivered`; o cancelamento é possível até a entrega.
  """

  import Ecto.Query, warn: false

  alias Encomendei.Catalog.Product
  alias Encomendei.Repo
  alias Encomendei.Sales.{Customer, Order, OrderItem}

  @topic "orders"

  @type place_error :: :empty_cart | :unavailable_product | Ecto.Changeset.t()
  @type status_error :: :invalid_transition | Ecto.Changeset.t()

  @spec subscribe() :: :ok | {:error, term()}
  def subscribe, do: Phoenix.PubSub.subscribe(Encomendei.PubSub, @topic)

  @doc """
  Lista encomendas com cliente e itens, da entrega mais próxima para a mais
  distante. A opção `:status` aceita um status ou uma lista deles.
  """
  @spec list_orders(keyword()) :: [Order.t()]
  def list_orders(opts \\ []) do
    Order
    |> filter_status(opts[:status])
    |> order_by([o], asc: o.delivery_at)
    |> preload([:customer, items: :product])
    |> Repo.all()
  end

  defp filter_status(query, nil), do: query
  defp filter_status(query, status), do: where(query, [o], o.status in ^List.wrap(status))

  @type queue :: %{
          pending: [Order.t()],
          in_production: [Order.t()],
          delivered: [Order.t()],
          canceled: [Order.t()]
        }

  @recent_deliveries 10

  @doc """
  Fila de produção agrupada por status, para o painel da confeiteira.

  Encomendas pendentes e em produção aparecem completas, da entrega mais
  próxima para a mais distante. As entregues mostram só as #{@recent_deliveries}
  mais recentes, para o painel não crescer indefinidamente; o mesmo vale para
  as canceladas, que ficam visíveis para conferência.
  """
  @spec production_queue() :: queue()
  def production_queue do
    open = [status: [:pending, :in_production]] |> list_orders() |> Enum.group_by(& &1.status)

    %{
      pending: Map.get(open, :pending, []),
      in_production: Map.get(open, :in_production, []),
      delivered: recent_with_status(:delivered),
      canceled: recent_with_status(:canceled)
    }
  end

  defp recent_with_status(status) do
    Order
    |> where([o], o.status == ^status)
    |> order_by([o], desc: o.updated_at)
    |> limit(@recent_deliveries)
    |> with_details()
    |> Repo.all()
  end

  @spec get_order!(Ecto.UUID.t()) :: Order.t()
  def get_order!(id), do: Repo.get!(with_details(Order), id)

  @doc "Busca uma encomenda pelo id. Ids malformados são tratados como inexistentes."
  @spec fetch_order(term()) :: {:ok, Order.t()} | {:error, :not_found}
  def fetch_order(id) do
    with {:ok, uuid} <- Ecto.UUID.cast(id),
         %Order{} = order <- Repo.get(with_details(Order), uuid) do
      {:ok, order}
    else
      _not_found -> {:error, :not_found}
    end
  end

  defp with_details(query), do: preload(query, [:customer, items: :product])

  @doc """
  Registra uma encomenda feita pelo cliente.

  Espera `name`, `phone`, `delivery_at`, `notes` e `items`, uma lista de
  `product_id` e `quantity`. Linhas com quantidade zero ou negativa são
  descartadas. O total é a soma de `quantidade × preço atual` de cada item.

  Erros possíveis: `:empty_cart` (nenhum item válido), `:unavailable_product`
  (produto inexistente ou indisponível) ou um changeset com os campos
  inválidos (telefone, data de entrega, quantidade).
  """
  @spec place_order(map()) :: {:ok, Order.t()} | {:error, place_error()}
  def place_order(attrs) do
    with {:ok, lines} <- cart_lines(attrs),
         {:ok, order} <- Repo.transact(fn -> persist_order(attrs, lines) end) do
      broadcast({:order_created, order.id})
      {:ok, get_order!(order.id)}
    end
  end

  defp persist_order(attrs, lines) do
    with :ok <- validate_checkout(attrs),
         {:ok, customer} <- upsert_customer(attrs),
         {:ok, order} <- insert_order(customer, attrs, lines),
         {:ok, _items} <- insert_items(order, lines) do
      {:ok, order}
    end
  end

  defp cart_lines(attrs) do
    with {:ok, lines} <- requested_lines(attrs),
         {:ok, lines} <- normalize_ids(lines) do
      price_lines(lines)
    end
  end

  defp requested_lines(attrs) do
    attrs
    |> fetch(:items)
    |> List.wrap()
    |> Enum.map(&%{product_id: fetch(&1, :product_id), quantity: quantity(&1)})
    |> Enum.filter(&(&1.quantity > 0))
    |> case do
      [] -> {:error, :empty_cart}
      lines -> {:ok, lines}
    end
  end

  defp normalize_ids(lines) do
    lines
    |> Enum.reduce_while({:ok, []}, fn %{product_id: id} = line, {:ok, acc} ->
      case Ecto.UUID.cast(id) do
        {:ok, uuid} -> {:cont, {:ok, [%{line | product_id: uuid} | acc]}}
        :error -> {:halt, {:error, :unavailable_product}}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      error -> error
    end
  end

  defp price_lines(lines) do
    ids = lines |> Enum.map(& &1.product_id) |> Enum.uniq()

    prices =
      from(p in Product, where: p.id in ^ids and p.available, select: {p.id, p.price_cents})
      |> Repo.all()
      |> Map.new()

    case prices do
      prices when map_size(prices) == length(ids) ->
        {:ok, Enum.map(lines, &Map.put(&1, :unit_price_cents, Map.fetch!(prices, &1.product_id)))}

      _some_missing ->
        {:error, :unavailable_product}
    end
  end

  # Valida cliente e entrega juntos para devolver todos os erros de uma vez.
  defp validate_checkout(attrs) do
    customer =
      Customer.changeset(%Customer{}, %{name: fetch(attrs, :name), phone: fetch(attrs, :phone)})

    order =
      Order.changeset(%Order{}, %{
        customer_id: Ecto.UUID.generate(),
        delivery_at: fetch(attrs, :delivery_at),
        notes: fetch(attrs, :notes)
      })

    merged =
      Enum.reduce(customer.errors, order, fn {field, {message, opts}}, changeset ->
        Ecto.Changeset.add_error(changeset, field, message, opts)
      end)

    if merged.valid?, do: :ok, else: {:error, %{merged | action: :insert}}
  end

  defp upsert_customer(attrs) do
    params = %{name: fetch(attrs, :name), phone: fetch(attrs, :phone)}
    changeset = Customer.changeset(%Customer{}, params)

    with {:ok, %Customer{phone: phone}} <- Ecto.Changeset.apply_action(changeset, :validate) do
      case Repo.get_by(Customer, phone: phone) do
        nil ->
          Repo.insert(changeset)

        %Customer{} = known ->
          known |> Customer.changeset(Map.take(params, [:name])) |> Repo.update()
      end
    end
  end

  defp insert_order(customer, attrs, lines) do
    total = lines |> Enum.map(&(&1.quantity * &1.unit_price_cents)) |> Enum.sum()

    %Order{}
    |> Order.changeset(%{
      customer_id: customer.id,
      delivery_at: fetch(attrs, :delivery_at),
      notes: fetch(attrs, :notes),
      total_cents: total
    })
    |> Repo.insert()
  end

  defp insert_items(order, lines) do
    lines
    |> Enum.reduce_while({:ok, []}, fn line, {:ok, acc} ->
      case %OrderItem{}
           |> OrderItem.changeset(Map.put(line, :order_id, order.id))
           |> Repo.insert() do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  @doc """
  Status para os quais a encomenda pode ir a partir do atual.

  Encomendas entregues ou canceladas estão encerradas e não aceitam mudança.
  """
  @spec next_statuses(Order.t() | Order.status()) :: [Order.status()]
  def next_statuses(%Order{status: status}), do: next_statuses(status)

  def next_statuses(status),
    do: for(to <- Order.statuses(), transition(status, to) == :ok, do: to)

  defp transition(:pending, :in_production), do: :ok
  defp transition(:pending, :canceled), do: :ok
  defp transition(:in_production, :delivered), do: :ok
  defp transition(:in_production, :canceled), do: :ok
  defp transition(_from, _to), do: {:error, :invalid_transition}

  @doc """
  Muda o status da encomenda e avisa o painel e a página do cliente em tempo real.

  Retorna `{:error, :invalid_transition}` quando o fluxo não permite a mudança,
  como pular a produção ou reabrir uma encomenda encerrada.
  """
  @spec update_status(Order.t(), Order.status()) :: {:ok, Order.t()} | {:error, status_error()}
  def update_status(%Order{status: from} = order, to) when is_atom(to) do
    with :ok <- transition(from, to),
         {:ok, updated} <- order |> Order.status_changeset(to) |> Repo.update() do
      broadcast({:order_updated, updated.id})
      {:ok, updated}
    end
  end

  @spec list_customers() :: [Customer.t()]
  def list_customers, do: Repo.all(from c in Customer, order_by: c.name)

  @spec get_customer!(Ecto.UUID.t()) :: Customer.t()
  def get_customer!(id), do: Repo.get!(Customer, id)

  defp broadcast(message), do: Phoenix.PubSub.broadcast(Encomendei.PubSub, @topic, message)

  defp fetch(map, key), do: Map.get(map, key) || Map.get(map, to_string(key))

  defp quantity(item), do: item |> fetch(:quantity) |> to_quantity()

  defp to_quantity(n) when is_integer(n), do: n

  defp to_quantity(text) when is_binary(text) do
    case Integer.parse(text) do
      {n, _rest} -> n
      :error -> 0
    end
  end

  defp to_quantity(_other), do: 0
end
