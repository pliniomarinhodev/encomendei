# Roteiro do vídeo (uma pessoa, cerca de 8 minutos)

Formato dos vídeos de outros grupos: **uma pessoa** apresenta os slides e, no final, **mostra o sistema funcionando**
e o código no GitHub. Duração boa: 7 a 9 minutos (o limite é 10). Falar devagar, em linguagem simples.
Texto entre colchetes `[...]` só você sabe. Não invente: diga só o que de fato aconteceu.

## Antes de gravar
- Abra o **site publicado** (https://encomendei.onrender.com) uns 5 minutos antes, para ele não estar dormindo.
- Cadastre alguns produtos em `/admin/produtos` (o banco publicado começa vazio), para a demonstração ter o que mostrar.
- Abas prontas: slides (PDF em tela cheia), GitHub do projeto, cardápio publicado, painel (já logado em outra aba).
- **Slides:** `~/Projetos/univesp/docs/apresentacao_encomendei.pdf` (14 slides). O slide 12 traz só o próximo passo (apresentar à Sra. Michele); se ela já viu o sistema, me peça para atualizar com o que ela de fato disse.
- Deixe a **câmera visível no canto** da tela (OBS), como no vídeo de referência.

## Roteiro por slide

| Tempo | Slide | O que dizer |
|---|---|---|
| 0:00–0:40 | 1. Título | "Olá. Eu sou o Plinio Henrique Sgobi Marinho, RA 24202364, da Univesp. Este é o Projeto Integrador em Computação II, grupo 5, turma A2026S2N4. O grupo é formado por Danilo Henrique Scateloni, Fernando Donizeti Abachi, Paulo Patrick Rodrigues Martins e por mim. Nossa tutora é a Elaine Cecilia Gomes Macagnan. O trabalho se chama Encomendei, uma aplicação web para automação de encomendas de confeitaria." |
| 0:40–1:25 | 2. Problema | "A comunidade é a confeitaria familiar da Sra. Michele, que faz bolos caseiros. Hoje os pedidos chegam por mensagens e são anotados no papel. Isso causa sobrecarga, risco de esquecer pedidos e dificuldade para organizar as entregas. Nossa pergunta foi: como uma aplicação web com banco de dados pode reduzir essa sobrecarga e melhorar a gestão das encomendas?" |
| 1:25–1:55 | 3. Objetivos | "O objetivo foi criar um sistema em que o cliente faz a encomenda pela internet e a confeiteira acompanha tudo em um painel, sem depender de papel e de mensagens soltas." |
| 1:55–2:20 | 4. Etapas | "Seguimos as etapas da Univesp: **ouvir** a comunidade e levantar as necessidades, **criar** a solução e **implementar** o sistema funcionando." |
| 2:20–3:00 | 5. Tecnologias | "Usamos Elixir com o framework Phoenix, banco de dados PostgreSQL, Docker para empacotar, GitHub para guardar o código e Render para publicar na internet. O sistema tem 124 testes automatizados, passou na verificação automática de acessibilidade e tem login para o painel." |
| 3:00–3:30 | 6. Banco de dados | "Este é o banco: clientes, pedidos, itens de pedido e produtos. Um cliente faz vários pedidos, um pedido tem vários itens, e cada item é um produto." |
| 3:30–3:50 | 7. Cardápio | "Esta é a tela do cliente: ele escolhe os produtos, vê o carrinho e preenche nome e telefone. A entrega é para o mais rápido possível, ou ele pode agendar uma data." |
| 3:50–4:10 | 8. Pedido enviado | "Ao enviar, o cliente recebe o número do pedido e pode acompanhar depois, informando o número e o telefone." |
| 4:10–4:30 | 9. Painel | "Esta é a tela da confeiteira: os pedidos aparecem separados por situação, e ela muda o andamento com um clique." |
| 4:30–4:50 | 10. Relatórios | "Nos relatórios, ela vê o total vendido, os pedidos em aberto e pode baixar os dados em planilha." |
| 4:50–5:10 | 11. Celular | "Tudo funciona bem no celular, que é onde a maioria dos clientes vai usar." |
| 5:10–5:50 | 12. Resultados | "**[DIGA O QUE DE FATO ACONTECEU com a Sra. Michele: quando mostraram, o que ela achou, ajustes.]** Se ainda não foi validado: "A validação com a Sra. Michele está prevista para [DATA]. O sistema está funcionando, publicado na internet, com 124 testes automatizados e sem problemas nas verificações automáticas de acessibilidade."" |
| 5:50–6:30 | 13. Disciplinas e melhorias | "Aplicamos programação web, banco de dados, engenharia de software, com levantamento de requisitos e testes, e interface humano-máquina, na acessibilidade e no uso pelo celular. Como melhorias futuras: avisos automáticos por mensagem, pagamento online e atender mais de uma confeitaria." |
| 6:30–7:00 | 14. Obrigado | "Agradeço à Sra. Michele, que cedeu a ideia do projeto, à tutora Elaine e ao meu grupo. O sistema está publicado neste endereço, e o código está no GitHub. Agora vou mostrar o sistema funcionando." (URL e QR code na tela) |
| 7:00–9:00 | **Demonstração** | Roteiro abaixo |

Os slides 7 a 10 são rápidos de propósito (20 segundos cada): o tempo é para a demonstração ao vivo.

## Demonstração (2 minutos)
1. **GitHub**: "O código está no GitHub, com o histórico de alterações e o README." Mostrar a lista de arquivos e os commits. *(Veja a nota no final sobre autoria.)*
2. **Site publicado**: mostrar o endereço `encomendei.onrender.com` na barra: "Está hospedado na internet, no Render."
3. **Cardápio**: adicionar produtos, preencher nome e telefone, enviar (mostre também a opção "Agendar para uma data"). Mostrar o **número do pedido** na confirmação.
4. **Painel** (`/entrar`, usuário e senha): "O pedido apareceu sozinho." Clicar em **Iniciar produção** e mostrar a outra aba mudando de status.
5. **Busca e relatórios**: buscar um nome e abrir `/admin/relatorios`.
6. Fechar: "Era isso. Obrigado pela atenção."

## Nota sobre o GitHub
No outro vídeo, o apresentador mostra que mais de uma pessoa mexeu no código. Neste repositório, hoje, **todos os commits são de uma só pessoa**.
Não diga que o grupo todo programou se não foi assim. Duas saídas honestas: (1) dizer apenas que o código está versionado no GitHub; (2) cada colega
fazer uma contribuição **de verdade** (ex.: o próprio texto do relatório, os dados dos produtos, uma melhoria pequena), com a conta dele no GitHub.

## Dicas
- Grave com OBS Studio ou o Google Meet (gravando a tela), microfone ligado. Teste de 20 segundos antes.
- Zoom do navegador em 125% na demonstração. Se errar, continue; se passar de 10 minutos, corte o item 5 da demonstração.
- Suba no YouTube como **Não listado**, copie o link para a capa do relatório e para o AVA, e abra em janela anônima para conferir.
