defmodule EncomendeiWeb.Cart do
  @moduledoc """
  Carrinho do cliente durante a navegação no cardápio: um mapa de
  `product_id` para quantidade, com no máximo 99 unidades por produto.
  """

  alias Encomendei.Catalog.Product

  @max_quantity 99

  @type t :: %{optional(String.t()) => pos_integer()}

  @spec new() :: t()
  def new, do: %{}

  @spec add(t(), String.t()) :: t()
  def add(cart, product_id), do: Map.update(cart, product_id, 1, &min(&1 + 1, @max_quantity))

  @spec remove(t(), String.t()) :: t()
  def remove(cart, product_id) do
    case cart do
      %{^product_id => 1} -> Map.delete(cart, product_id)
      %{^product_id => quantity} -> Map.put(cart, product_id, quantity - 1)
      _absent -> cart
    end
  end

  @spec quantity(t(), Product.t()) :: non_neg_integer()
  def quantity(cart, %Product{id: id}), do: Map.get(cart, id, 0)

  @spec empty?(t()) :: boolean()
  def empty?(cart), do: cart == %{}

  @doc "Itens do carrinho com o produto e o subtotal, na ordem do cardápio."
  @spec lines(t(), [Product.t()]) :: [
          %{product: Product.t(), quantity: pos_integer(), subtotal_cents: integer()}
        ]
  def lines(cart, products) do
    for product <- products, (quantity = quantity(cart, product)) > 0 do
      %{product: product, quantity: quantity, subtotal_cents: quantity * product.price_cents}
    end
  end

  @spec total_cents(t(), [Product.t()]) :: integer()
  def total_cents(cart, products), do: cart |> lines(products) |> Enum.sum_by(& &1.subtotal_cents)

  @doc "Itens no formato esperado por `Encomendei.Sales.place_order/1`."
  @spec to_items(t()) :: [%{String.t() => term()}]
  def to_items(cart),
    do: for({id, quantity} <- cart, do: %{"product_id" => id, "quantity" => quantity})
end
