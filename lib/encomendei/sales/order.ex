defmodule Encomendei.Sales.Order do
  @moduledoc """
  Encomenda de um cliente, com data de entrega e total em centavos.

  O total é sempre calculado pelo contexto `Encomendei.Sales` a partir dos
  preços do catálogo no momento do pedido; alterações posteriores de preço
  não afetam encomendas já registradas.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Encomendei.Sales.{Customer, OrderItem}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:pending, :in_production, :delivered, :canceled]
  @status_by_name Map.new(@statuses, &{Atom.to_string(&1), &1})

  @type status :: :pending | :in_production | :delivered | :canceled
  @type t :: %__MODULE__{}

  schema "orders" do
    field :delivery_at, :utc_datetime
    # false: o cliente quer "o mais rápido possível" e `delivery_at` guarda a hora do pedido
    field :scheduled, :boolean, default: true
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :total_cents, :integer, default: 0
    field :notes, :string
    field :number, :integer, read_after_writes: true

    belongs_to :customer, Customer
    has_many :items, OrderItem

    timestamps(type: :utc_datetime)
  end

  @spec statuses() :: [status()]
  def statuses, do: @statuses

  @doc "Converte o nome de um status recebido de fora (formulário, API) no atom correspondente."
  @spec parse_status(term()) :: {:ok, status()} | {:error, :invalid_status}
  def parse_status(name) when is_binary(name) do
    case @status_by_name do
      %{^name => status} -> {:ok, status}
      _ -> {:error, :invalid_status}
    end
  end

  def parse_status(_other), do: {:error, :invalid_status}

  @doc """
  Valida os dados de uma nova encomenda.

  Sem `delivery_at`, o pedido é para "o mais rápido possível": `scheduled` fica
  `false` e a entrega recebe a hora do pedido. Com `delivery_at`, o cliente agendou
  e a data precisa estar no futuro, pois a confeiteira só produz sob encomenda;
  não há antecedência mínima configurada.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:delivery_at, :notes, :customer_id, :total_cents])
    |> validate_change(:delivery_at, &validate_future/2)
    |> default_to_asap()
    |> validate_required([:delivery_at, :customer_id])
    |> validate_length(:notes, max: 500)
    |> validate_number(:total_cents, greater_than_or_equal_to: 0)
    |> assoc_constraint(:customer)
    |> unique_constraint(:number)
    |> check_constraint(:total_cents, name: :total_cents_non_negative)
  end

  @spec status_changeset(t(), status()) :: Ecto.Changeset.t()
  def status_changeset(order, status) do
    order
    |> cast(%{status: status}, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> check_constraint(:status, name: :status_valid)
  end

  # Só vale quando a data não foi informada; data inválida continua sendo erro.
  defp default_to_asap(changeset) do
    if is_nil(get_field(changeset, :delivery_at)) and
         not Keyword.has_key?(changeset.errors, :delivery_at) do
      changeset
      |> put_change(:delivery_at, DateTime.utc_now() |> DateTime.truncate(:second))
      |> put_change(:scheduled, false)
    else
      changeset
    end
  end

  defp validate_future(:delivery_at, delivery_at) do
    case DateTime.compare(delivery_at, DateTime.utc_now()) do
      :gt -> []
      _past_or_now -> [delivery_at: "deve ser uma data futura"]
    end
  end
end
