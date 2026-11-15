defmodule EncomendeiWeb.Format do
  @moduledoc "Formatação de valores para a interface em português."

  # Brasil não usa horário de verão desde 2019: fuso fixo UTC-3.
  @offset_seconds -3 * 3600

  @doc "Link do WhatsApp (`wa.me`) para um telefone com DDD, com texto inicial opcional."
  @spec whatsapp_url(String.t(), String.t()) :: String.t()
  def whatsapp_url(phone, text) do
    digits = String.replace(phone, ~r/\D/, "")
    "https://wa.me/55#{digits}?" <> URI.encode_query([text: text], :rfc3986)
  end

  @doc "Número do pedido como o cliente e a confeiteira o chamam, por exemplo `#42`."
  def order_number(%{number: number}) when is_integer(number), do: "##{number}"
  def order_number(_order), do: ""

  def money(cents) when is_integer(cents) do
    reais = div(cents, 100)
    centavos = cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")

    reais =
      reais
      |> Integer.to_string()
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
      |> String.reverse()

    "R$ #{reais},#{centavos}"
  end

  def money(_), do: "R$ 0,00"

  def datetime(%DateTime{} = dt) do
    dt |> DateTime.add(@offset_seconds) |> Calendar.strftime("%d/%m/%Y às %H:%M")
  end

  @doc "Converte o valor de um input datetime-local (horário de Brasília) para UTC."
  def parse_local(nil), do: nil
  def parse_local(""), do: nil

  def parse_local(value) when is_binary(value) do
    value = if String.length(value) == 16, do: value <> ":00", else: value

    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive} ->
        naive |> DateTime.from_naive!("Etc/UTC") |> DateTime.add(-@offset_seconds)

      _ ->
        nil
    end
  end

  def status_label(:pending), do: "Pendente"
  def status_label(:in_production), do: "Em produção"
  def status_label(:delivered), do: "Entregue"
  def status_label(:canceled), do: "Cancelado"

  def phone(<<ddd::binary-size(2), a::binary-size(5), b::binary-size(4)>>),
    do: "(#{ddd}) #{a}-#{b}"

  def phone(<<ddd::binary-size(2), a::binary-size(4), b::binary-size(4)>>),
    do: "(#{ddd}) #{a}-#{b}"

  def phone(other), do: other

  @doc "Valor em reais para preencher campo de formulário (ex.: `4550` → `\"45,50\"`)."
  def price_input(cents) when is_integer(cents) do
    reais = div(cents, 100)
    centavos = cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{reais},#{centavos}"
  end

  def price_input(_), do: ""

  @doc "Data de entrega curta, no horário de Brasília (ex.: `12/11 às 14:00`)."
  def delivery_short(%DateTime{} = dt) do
    dt |> DateTime.add(@offset_seconds) |> Calendar.strftime("%d/%m às %H:%M")
  end

  @doc "Entrega para a lista: a data, ou \"A confirmar\" se o cliente não agendou."
  def delivery_label(%{scheduled: false}), do: "A confirmar"
  def delivery_label(%{delivery_at: %DateTime{} = dt}), do: delivery_short(dt)

  @doc "Soma dos totais de uma lista de encomendas, em centavos."
  def total_cents(orders), do: orders |> Enum.map(& &1.total_cents) |> Enum.sum()

  @doc "Resumo dos itens em uma linha (ex.: `2× Bolo de Limão, 1× Brigadeiros`)."
  def items_summary(%{items: items}) do
    Enum.map_join(items, ", ", &"#{&1.quantity}× #{&1.product.name}")
  end

  @doc """
  Quão perto está a entrega, no horário de Brasília: `:overdue` se já passou,
  `:today`, `:tomorrow` ou `:later`. Pedido "o mais rápido possível" conta como `:today`.
  """
  def urgency(%{scheduled: false}, %DateTime{}), do: :today

  def urgency(%{delivery_at: delivery_at}, %DateTime{} = now) do
    local_date = &(&1 |> DateTime.add(@offset_seconds) |> DateTime.to_date())

    case {DateTime.compare(delivery_at, now),
          Date.diff(local_date.(delivery_at), local_date.(now))} do
      {:lt, _days} -> :overdue
      {_order, 0} -> :today
      {_order, 1} -> :tomorrow
      {_order, _days} -> :later
    end
  end
end
