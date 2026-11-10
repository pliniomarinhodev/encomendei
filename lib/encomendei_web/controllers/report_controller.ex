defmodule EncomendeiWeb.ReportController do
  use EncomendeiWeb, :controller
  alias Encomendei.Reports

  @header ~w(pedido entrega status cliente produto quantidade preco_unitario_reais)

  def orders_csv(conn, _params) do
    rows =
      for r <- Reports.export_rows() do
        [
          r.pedido,
          DateTime.to_iso8601(r.entrega),
          r.status,
          r.cliente,
          r.produto,
          r.quantidade,
          centavos(r.preco_unitario_cents)
        ]
      end

    csv =
      [@header | rows] |> Enum.map_join("\r\n", fn row -> Enum.map_join(row, ",", &cell/1) end)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="pedidos.csv"))
    |> send_resp(200, "﻿" <> csv <> "\r\n")
  end

  defp centavos(c), do: :erlang.float_to_binary(c / 100, decimals: 2)

  # Escapa aspas e neutraliza fórmulas (=, +, -, @) que o Excel executaria
  defp cell(value) do
    s = to_string(value)
    s = if String.starts_with?(s, ["=", "+", "-", "@"]), do: "'" <> s, else: s
    ~s("#{String.replace(s, "\"", "\"\"")}")
  end
end
