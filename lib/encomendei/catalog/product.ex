defmodule Encomendei.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :description, :string
    field :price_cents, :integer
    field :available, :boolean, default: false
    field :image_url, :string
    field :price, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @price_format ~r/^\d+([.,]\d{1,2})?$/

  @doc """
  Valida um produto.

  O preço pode ser informado em reais no campo `price` (ex.: `"45,50"`), que é
  convertido para `price_cents`. Informar `price_cents` diretamente também funciona.
  """
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :price_cents, :available, :image_url, :price])
    |> put_price_cents()
    |> validate_required([:name, :price_cents])
    |> validate_length(:name, max: 120)
    |> validate_image_url()
    |> validate_number(:price_cents, greater_than: 0)
    |> check_constraint(:price_cents, name: :price_cents_positive)
  end

  @doc """
  Indica se o texto é um link de imagem aceito: `http` ou `https`, com endereço.

  Outros esquemas (`javascript:`, `data:`) são recusados para que o link
  cadastrado nunca execute código nas páginas do cardápio.
  """
  @spec image_url?(term()) :: boolean()
  def image_url?(url) when is_binary(url) do
    match?(
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and host not in [nil, ""],
      URI.parse(url)
    )
  end

  def image_url?(_other), do: false

  defp validate_image_url(changeset) do
    changeset
    |> validate_length(:image_url, max: 255)
    |> validate_change(:image_url, fn :image_url, url ->
      if image_url?(url), do: [], else: [image_url: "informe um link começando com https://"]
    end)
  end

  defp put_price_cents(changeset) do
    case fetch_change(changeset, :price) do
      {:ok, text} -> apply_price(changeset, parse_price(text))
      :error -> changeset
    end
  end

  defp apply_price(changeset, {:ok, cents}), do: put_change(changeset, :price_cents, cents)

  defp apply_price(changeset, :error),
    do: add_error(changeset, :price, "informe um valor como 45,00")

  defp parse_price(text) do
    normalized = text |> String.replace(~r/R\$|\s/u, "") |> String.replace(",", ".")

    case Regex.match?(@price_format, normalized) do
      true -> {:ok, normalized |> Decimal.new() |> Decimal.mult(100) |> Decimal.to_integer()}
      false -> :error
    end
  end
end
