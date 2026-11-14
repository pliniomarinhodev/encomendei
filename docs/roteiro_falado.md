# Roteiro do vídeo (uma pessoa, cerca de 8 minutos)

Formato dos vídeos de outros grupos: **uma pessoa** apresenta alguns slides (6 a 8) e, no final, **mostra o sistema funcionando**
e o código no GitHub. Duração boa: 7 a 9 minutos (o limite é 10). Falar devagar, em linguagem simples.
Texto entre colchetes `[...]` só você sabe. Não invente: diga só o que de fato aconteceu.

## Antes de gravar
- `docker start encomendei-pg`, `mix phx.server`, `mix run priv/repo/demo.exs`, `mix run priv/repo/demo_photos.exs`.
- Abra o **site publicado** (https://encomendei.onrender.com) uns 5 minutos antes, para ele não estar dormindo.
- Abas prontas: cardápio, painel (já logado), GitHub do projeto, slides.
- Slides sugeridos: 1 Título e grupo · 2 Problema · 3 Objetivo e etapas (Ouvir, Criar, Implementar) · 4 Tecnologias e diagrama do banco (`docs/figuras/diagrama_banco.png`) · 5 Telas (as figuras do relatório) · 6 Resultados · 7 Disciplinas aplicadas · 8 Melhorias futuras e agradecimentos, com a **URL do sistema** na tela.

## Roteiro por bloco

| Tempo | Slide / tela | O que dizer |
|---|---|---|
| 0:00–0:50 | 1. Título | "Olá. Eu sou o Plinio Henrique Sgobi Marinho, RA 24202364, do Projeto Integrador em Computação II, grupo 5, turma A2026S2N4, do polo [POLO]. O grupo é formado por Danilo Henrique Scateloni, Fernando Donizeti Abachi, Paulo Patrick Rodrigues Martins e por mim. Nossa tutora é a Elaine Cecilia Gomes Macagnan. Nosso trabalho se chama Encomendei, uma aplicação web para automação de encomendas de bolos caseiros." |
| 0:50–1:50 | 2. Problema | "A comunidade é o negócio de bolos caseiros da Sra. Michele. Hoje os pedidos chegam por mensagens e são anotados no papel. Isso causa sobrecarga, risco de esquecer pedidos e dificuldade para organizar as entregas. Nossa pergunta foi: como uma aplicação web com banco de dados pode reduzir essa sobrecarga e melhorar a gestão das encomendas?" |
| 1:50–2:40 | 3. Objetivo e etapas | "O objetivo foi criar um sistema em que o cliente faz a encomenda pela internet e a confeiteira acompanha tudo em um painel. Seguimos as etapas da Univesp: **ouvir** a comunidade e levantar as necessidades, **criar** a solução e **implementar** o sistema funcionando." |
| 2:40–3:40 | 4. Tecnologias e banco | "Usamos Elixir com o framework Phoenix, banco de dados PostgreSQL, e o código fica no GitHub. Este diagrama mostra o banco: clientes, pedidos, itens de pedido e produtos. Um cliente faz vários pedidos, um pedido tem vários itens, e cada item é um produto." |
| 3:40–4:20 | 5. Telas | "Estas são as telas principais: o cardápio com o carrinho, a confirmação do pedido, o painel da confeiteira e os relatórios. Também funciona bem no celular." |
| 4:20–5:00 | 6. Resultados | "**[DIGA O QUE DE FATO ACONTECEU com a Sra. Michele: quando mostraram, o que ela achou, ajustes.]** Se ainda não foi validado: "A validação com a Sra. Michele está prevista para [DATA]. O sistema está funcionando, publicado na internet, com 124 testes automatizados e sem problemas de acessibilidade nas verificações automáticas."" |
| 5:00–5:40 | 7. Disciplinas | "Aplicamos programação web, banco de dados, engenharia de software, com levantamento de requisitos e testes, e interface humano-máquina, na acessibilidade e no uso pelo celular." |
| 5:40–6:20 | 8. Melhorias e agradecimentos | "Como melhorias futuras: avisos automáticos por mensagem, pagamento online e atender mais de uma confeitaria. Agradeço à Sra. Michele, que cedeu a ideia do projeto, à tutora Elaine e ao meu grupo. O sistema está publicado neste endereço." (URL na tela) |
| 6:20–8:30 | **Demonstração** | Roteiro abaixo |

## Demonstração (2 minutos)
1. **GitHub**: "O código está no GitHub, com o histórico de alterações e o README." Mostrar a lista de arquivos e os commits. *(Veja a nota no final sobre autoria.)*
2. **Site publicado**: mostrar o endereço `encomendei.onrender.com` na barra: "Está hospedado na internet, no Render."
3. **Cardápio**: adicionar produtos, preencher nome, telefone e data, enviar. Mostrar o **número do pedido** na confirmação.
4. **Painel** (`/entrar`, usuário e senha): "O pedido apareceu sozinho." Clicar em **Iniciar produção** e mostrar a outra aba mudando de status.
5. **Busca e relatórios**: buscar um nome e abrir `/admin/relatorios`.
6. Fechar: "Era isso. Obrigado pela atenção."

## Nota sobre o GitHub
No outro vídeo, o apresentador mostra que mais de uma pessoa mexeu no código. Neste repositório, hoje, **todos os commits são de uma só pessoa**.
Não diga que o grupo todo programou se não foi assim. Duas saídas honestas: (1) dizer apenas que o código está versionado no GitHub; (2) cada colega
fazer uma contribuição **de verdade** (ex.: o próprio texto do relatório, os dados dos produtos, uma melhoria pequena), com a conta dele no GitHub.

## Dicas
- Grave com OBS Studio ou o Google Meet (gravando a tela), microfone ligado. Teste de 20 segundos antes.
- Zoom do navegador em 125%. Se errar, continue; se passar de 10 minutos, corte o item 5 da demonstração.
- Suba no YouTube como **Não listado**, copie o link para a capa do relatório e para o AVA, e abra em janela anônima para conferir.
