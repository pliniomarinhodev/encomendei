# Encomendei

Sistema web de encomendas para pequenos negócios de confeitaria, desenvolvido no
Projeto Integrador em Computação II (UNIVESP, turma PJI240 – Grupo 5).

O cliente escolhe produtos no cardápio e envia a encomenda. A confeiteira acompanha
tudo em um painel que atualiza em tempo real (pendente → em produção → entregue).

## Requisitos do PI atendidos

| Requisito | Onde |
|---|---|
| Framework web | Phoenix 1.8 (Elixir) |
| Banco de dados | PostgreSQL via Ecto (`priv/repo/migrations`) |
| Script web (JavaScript) | Phoenix LiveView (carrinho e painel sem recarregar a página) |
| Nuvem | Oracle Cloud Always Free – ver [docs/DEPLOY_ORACLE.md](docs/DEPLOY_ORACLE.md) |
| API | JSON em `/api` (abaixo) |
| Acessibilidade | HTML semântico, rótulos ARIA, `aria-live`, link "ir para o conteúdo", tema claro/escuro, `lang="pt-BR"` |
| Análise de dados (opcional) | Relatórios em `/admin/relatorios` e exportação CSV |
| Controle de versão | git |
| Testes | ExUnit (`mix test`) |

## Rodando localmente

Requisitos: Elixir 1.19 / Erlang 28 e Docker.

```bash
docker run -d --name encomendei-pg -e POSTGRES_PASSWORD=postgres \
  -p 5433:5432 -v encomendei_pgdata:/var/lib/postgresql/data postgres:16

mix setup                      # dependências, banco, migrações e assets
mix run priv/repo/seeds.exs    # produtos de exemplo
mix phx.server
```

- Cardápio: <http://localhost:4000/>
- Painel: <http://localhost:4000/admin/pedidos> (dev: `admin` / `admin`)

Testes: `mix test`

## Telas

| Rota | Acesso | Função |
|---|---|---|
| `/` | público | Cardápio, carrinho e envio da encomenda |
| `/pedido/:id` | público (o `id` é um UUID difícil de adivinhar) | Confirmação ("Pedido #42 recebido") e status em tempo real |
| `/admin/pedidos` | senha | Fila de produção, com o número do pedido e botão de WhatsApp com mensagem pronta |
| `/admin/produtos` | senha | Cadastro de produtos |
| `/admin/relatorios` | senha | Faturamento, ticket médio, produtos mais vendidos e semanas; atualiza em tempo real |
| `/admin/relatorios/pedidos.csv` | senha | Exporta os itens vendidos em CSV (pronto para planilha), identificando o pedido pelo número |

## Número do pedido

Cada encomenda recebe um número sequencial (`#1`, `#2`, ...) gerado pelo próprio PostgreSQL
(coluna `identity` com índice único). É o número que a confeiteira e o cliente usam na conversa;
o UUID continua sendo o identificador interno e o da URL de acompanhamento. O número aparece na
confirmação, no painel, na mensagem de WhatsApp, no CSV e no campo `number` da API.

## Integridade dos dados

As regras valem no banco, não só nos changesets: `total_cents >= 0`, `quantity > 0`,
`unit_price_cents >= 0`, `products.price_cents > 0`, `status` restrito aos quatro valores e colunas essenciais `NOT NULL`.
Há índices em `orders (status, delivery_at)`, `orders (inserted_at)` e `orders (customer_id)`,
usados pelo painel e pelos relatórios.

## API JSON

Valores em centavos. Datas em ISO 8601 com fuso.

| Método e rota | Acesso | Descrição |
|---|---|---|
| `GET /api/products` | público | Produtos disponíveis |
| `POST /api/orders` | público | Cria pedido |
| `GET /api/orders/:id` | público | Consulta pedido |
| `GET /api/admin/orders?status=pending` | Basic Auth | Lista pedidos (filtro opcional) |
| `PATCH /api/admin/orders/:id/status` | Basic Auth | Muda o status |

Criar pedido:

```bash
curl -X POST http://localhost:4000/api/orders \
  -H 'content-type: application/json' \
  -d '{
    "name": "Ana", "phone": "19988887777",
    "delivery_at": "2026-11-20T14:00:00-03:00",
    "notes": "Sem nozes",
    "items": [{"product_id": "<id>", "quantity": 2}]
  }'
```

O pedido retorna `id` (UUID) e `number` (número sequencial).

Respostas: `201` com o pedido; `422` com `{"errors": {...}}` (data no passado, carrinho vazio,
produto indisponível, telefone inválido); `404` quando o pedido não existe.
O preço de cada item é sempre o do catálogo, nunca o enviado pelo cliente.

Status: `pending`, `in_production`, `delivered`, `canceled`. Transições permitidas:
`pending → in_production | canceled` e `in_production → delivered | canceled`.

## Estrutura

- `lib/encomendei/catalog` – produtos
- `lib/encomendei/sales` – clientes, pedidos, itens e regras de negócio
- `lib/encomendei/reports.ex` – consultas de análise de vendas
- `lib/encomendei_web/live` – telas (cardápio, confirmação, painel, produtos)
- `lib/encomendei_web/controllers/api` – API JSON
- `test/` – testes de regras, telas e API
