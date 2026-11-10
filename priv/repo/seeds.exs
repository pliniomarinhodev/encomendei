# Produtos de exemplo para desenvolvimento: mix run priv/repo/seeds.exs
alias Encomendei.{Catalog, Repo}
alias Encomendei.Catalog.Product

for {name, desc, price} <- [
      {"Bolo de Cenoura com Chocolate",
       "Massa fofinha com cobertura de chocolate. Serve 10 fatias.", 5500},
      {"Bolo de Fubá com Goiabada", "Receita caseira, ótimo para o café da tarde.", 4000},
      {"Bolo de Limão", "Cobertura cremosa de limão siciliano.", 4800},
      {"Brigadeiros (cento)", "100 unidades de brigadeiro tradicional.", 12000}
    ] do
  unless Repo.get_by(Product, name: name) do
    {:ok, _} =
      Catalog.create_product(%{
        name: name,
        description: desc,
        price_cents: price,
        available: true
      })
  end
end
