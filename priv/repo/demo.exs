# Dados de demonstração para o vídeo e as capturas de tela (somente desenvolvimento):
#   mix run priv/repo/seeds.exs && mix run priv/repo/demo.exs
if Mix.env() != :dev, do: raise("priv/repo/demo.exs só roda em desenvolvimento")

import Ecto.Query
alias Encomendei.{Catalog, Repo, Sales}
alias Encomendei.Sales.{Customer, Order, OrderItem}

Repo.delete_all(OrderItem)
Repo.delete_all(Order)
Repo.delete_all(Customer)

products = Map.new(Catalog.list_available_products(), &{&1.name, &1.id})
cenoura = products["Bolo de Cenoura com Chocolate"]
fuba = products["Bolo de Fubá com Goiabada"]
limao = products["Bolo de Limão"]
brigadeiro = products["Brigadeiros (cento)"]

demo = [
  # {cliente, telefone, itens, horas até a entrega, observação, status final}
  {"Helena Souza", "19991230001", [{cenoura, 1}], 3, "Escrever \"Parabéns, Pedro\"", :pending},
  {"Marcos Oliveira", "19991230002", [{fuba, 2}, {brigadeiro, 1}], 5, nil, :in_production},
  {"Carla Mendes", "19991230003", [{limao, 1}], 28, nil, :pending},
  {"Rafael Lima", "19991230004", [{cenoura, 2}], 30, "Sem cobertura", :in_production},
  {"Patrícia Alves", "19991230005", [{brigadeiro, 2}], 52, "Festa infantil, 14h", :pending},
  {"Bruno Costa", "19991230006", [{fuba, 1}], 76, nil, :pending},
  {"Juliana Rocha", "19991230007", [{limao, 2}, {cenoura, 1}], 100, nil, :pending},
  {"Eduardo Santos", "19991230008", [{cenoura, 1}], 2, nil, :delivered},
  {"Fernanda Dias", "19991230009", [{brigadeiro, 1}], 2, nil, :delivered},
  {"Lucas Pereira", "19991230010", [{fuba, 1}], 2, nil, :canceled},
  {"Aline Ribeiro", "19991230011", [{limao, 1}], 1, "Entregar na portaria", :pending}
]

for {name, phone, items, hours, notes, final} <- demo do
  {:ok, order} =
    Sales.place_order(%{
      "name" => name,
      "phone" => phone,
      "notes" => notes,
      "delivery_at" => DateTime.add(DateTime.utc_now(), hours * 3600),
      "items" => for({id, quantity} <- items, do: %{"product_id" => id, "quantity" => quantity})
    })

  path =
    case final do
      :pending -> []
      :in_production -> [:in_production]
      :delivered -> [:in_production, :delivered]
      :canceled -> [:canceled]
    end

  Enum.reduce(path, order, fn status, acc ->
    {:ok, updated} = Sales.update_status(acc, status)
    updated
  end)
end

# Uma encomenda atrasada: a entrega passou e ela ainda não foi para produção
overdue = Repo.one!(from o in Order, join: c in assoc(o, :customer), where: c.name == "Aline Ribeiro")
Repo.update_all(from(o in Order, where: o.id == ^overdue.id), set: [delivery_at: DateTime.add(DateTime.utc_now(), -2 * 3600) |> DateTime.truncate(:second)])

IO.puts("#{length(demo)} encomendas de demonstração criadas")
