defmodule Encomendei.Shop.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  alias Encomendei.Images

  @type t :: %__MODULE__{}

  @primary_key {:id, :integer, autogenerate: false}
  schema "shop_settings" do
    field :name, :string

    # Os bytes ficam no banco (disco do plano grátis é apagado) e não vêm nas consultas comuns.
    field :logo_data, :binary, load_in_query: false
    field :logo_type, :string
    field :remove_logo, :boolean, virtual: true, default: false

    timestamps(type: :utc_datetime)
  end

  @doc "Valida nome e logo da loja."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:name, :logo_data, :remove_logo])
    |> validate_required([:name])
    |> validate_length(:name, max: 60)
    |> apply_remove_logo()
    |> validate_logo()
    |> check_constraint(:id, name: :single_row)
  end

  # A loja vem do banco sem os bytes do logo, então `nil` sozinho não seria uma mudança.
  defp apply_remove_logo(changeset) do
    if get_change(changeset, :remove_logo),
      do: force_change(changeset, :logo_data, nil),
      else: changeset
  end

  defp validate_logo(changeset) do
    case fetch_change(changeset, :logo_data) do
      {:ok, nil} ->
        put_change(changeset, :logo_type, nil)

      {:ok, data} ->
        cond do
          byte_size(data) > Images.max_bytes() ->
            add_error(changeset, :logo_data, "o logo deve ter até 2 MB")

          type = Images.detect_type(data) ->
            put_change(changeset, :logo_type, type)

          true ->
            add_error(changeset, :logo_data, "envie uma imagem JPG, PNG ou WebP")
        end

      :error ->
        changeset
    end
  end
end
