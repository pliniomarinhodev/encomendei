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

    # A foto enviada fica no banco: no plano grátis do Render o disco é apagado a cada reinício.
    # `load_in_query: false` evita carregar os bytes nas listas; a rota de imagens busca à parte.
    field :image_data, :binary, load_in_query: false
    field :image_type, :string
    field :price, :string, virtual: true
    field :remove_image, :boolean, virtual: true, default: false

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
    |> cast(attrs, [
      :name,
      :description,
      :price_cents,
      :available,
      :image_url,
      :image_data,
      :remove_image,
      :price
    ])
    |> put_price_cents()
    |> validate_required([:name, :price_cents])
    |> validate_length(:name, max: 120)
    |> validate_image_url()
    |> apply_remove_image()
    |> validate_image_data()
    |> validate_number(:price_cents, greater_than: 0)
    |> check_constraint(:price_cents, name: :price_cents_positive)
  end

  @doc "Tamanho máximo da foto enviada, em bytes."
  defdelegate max_image_bytes, to: Encomendei.Images, as: :max_bytes

  @doc "Tipo da imagem pelos bytes do arquivo; veja `Encomendei.Images.detect_type/1`."
  defdelegate detect_image_type(data), to: Encomendei.Images, as: :detect_type

  @doc "Endereço da foto do produto: a enviada (se houver) ou o link cadastrado."
  @spec image_src(t()) :: String.t() | nil
  def image_src(%__MODULE__{image_type: type, id: id, updated_at: updated_at})
      when is_binary(type) do
    "/imagens/produtos/#{id}?v=#{DateTime.to_unix(updated_at)}"
  end

  def image_src(%__MODULE__{image_url: url}), do: if(image_url?(url), do: url)

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

  # O produto vem do banco sem os bytes da foto, então `nil` sozinho não seria uma mudança.
  defp apply_remove_image(changeset) do
    if get_change(changeset, :remove_image),
      do: force_change(changeset, :image_data, nil),
      else: changeset
  end

  defp validate_image_data(changeset) do
    case fetch_change(changeset, :image_data) do
      {:ok, nil} ->
        put_change(changeset, :image_type, nil)

      {:ok, data} ->
        cond do
          byte_size(data) > Encomendei.Images.max_bytes() ->
            add_error(changeset, :image_data, "a foto deve ter até 2 MB")

          type = detect_image_type(data) ->
            put_change(changeset, :image_type, type)

          true ->
            add_error(changeset, :image_data, "envie uma imagem JPG, PNG ou WebP")
        end

      :error ->
        changeset
    end
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
