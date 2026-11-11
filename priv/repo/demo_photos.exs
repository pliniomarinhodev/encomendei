# Coloca fotos ilustrativas nos produtos de demonstração (somente desenvolvimento).
# Uso: mix run priv/repo/demo_photos.exs
# Créditos das imagens: priv/static/images/demo/CREDITS.md
import Ecto.Query
alias Encomendei.{Catalog.Product, Repo}

photos = %{
  "Bolo de Cenoura com Chocolate" => "bolo-de-cenoura",
  "Bolo de Fubá com Goiabada" => "bolo-de-fuba",
  "Bolo de Limão" => "bolo-de-limao",
  "Brigadeiros (cento)" => "brigadeiros"
}

for {name, file} <- photos do
  url = "http://localhost:4000/images/demo/#{file}.jpg"
  Repo.update_all(from(p in Product, where: p.name == ^name), set: [image_url: url])
end

IO.puts("Fotos de demonstração aplicadas.")
