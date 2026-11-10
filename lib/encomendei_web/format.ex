defmodule EncomendeiWeb.Format do
  @moduledoc "Formatação de valores para a interface em português."

  # Brasil não usa horário de verão desde 2019: fuso fixo UTC-3.
  @offset_seconds -3 * 3600

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
end
