defmodule EncomendeiWeb.FormatTest do
  use ExUnit.Case, async: true

  import EncomendeiWeb.Format

  defp at(iso), do: elem(DateTime.from_iso8601(iso), 1)

  test "money/1" do
    assert money(0) == "R$ 0,00"
    assert money(5) == "R$ 0,05"
    assert money(4550) == "R$ 45,50"
    assert money(123_456_789) == "R$ 1.234.567,89"
  end

  test "price_input/1 gera o valor para o campo de formulário" do
    assert price_input(4550) == "45,50"
    assert price_input(99) == "0,99"
    assert price_input(nil) == ""
  end

  test "parse_local/1 converte horário de Brasília para UTC" do
    assert parse_local("2026-11-20T14:00") == at("2026-11-20T17:00:00Z")
    assert parse_local("") == nil
    assert parse_local("lixo") == nil
  end

  test "delivery_short/1 mostra no horário de Brasília" do
    assert delivery_short(at("2026-11-20T17:00:00Z")) == "20/11 às 14:00"
  end

  describe "urgency/2" do
    # agora = 20/11 às 12:00 em Brasília
    @now ~U[2026-11-20 15:00:00Z]

    test "atrasada quando a entrega já passou" do
      assert urgency(%{delivery_at: at("2026-11-20T14:00:00Z")}, @now) == :overdue
      assert urgency(%{delivery_at: at("2026-11-19T20:00:00Z")}, @now) == :overdue
    end

    test "hoje, amanhã e depois, pela data de Brasília" do
      assert urgency(%{delivery_at: at("2026-11-20T20:00:00Z")}, @now) == :today
      assert urgency(%{delivery_at: at("2026-11-21T20:00:00Z")}, @now) == :tomorrow
      assert urgency(%{delivery_at: at("2026-11-25T20:00:00Z")}, @now) == :later
    end

    test "meia-noite UTC ainda é o dia anterior em Brasília" do
      # 21/11 01:00 UTC = 20/11 22:00 em Brasília, ainda hoje
      assert urgency(%{delivery_at: at("2026-11-21T01:00:00Z")}, @now) == :today
    end
  end

  test "items_summary/1 e total_cents/1" do
    order = %{
      items: [%{quantity: 2, product: %{name: "Bolo"}}, %{quantity: 1, product: %{name: "Torta"}}]
    }

    assert items_summary(order) == "2× Bolo, 1× Torta"
    assert total_cents([%{total_cents: 100}, %{total_cents: 250}]) == 350
    assert total_cents([]) == 0
  end
end
