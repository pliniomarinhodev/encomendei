# Roteiro do vídeo (5 a 10 minutos)

Meta: **8 minutos**, para ficar dentro do limite mesmo com improvisos. O vídeo vai para o YouTube,
o link vai na capa do relatório e também no AVA. A correção do relatório depende do vídeo.

Os itens abaixo seguem os critérios de avaliação da tarefa "Q7 – Entrega do vídeo".

## Roteiro por bloco

| Tempo | Critério | O que mostrar e dizer | Quem |
|---|---|---|---|
| 0:00–0:40 | Identificação do grupo | Slide de abertura: título **Encomendei**, nomes e RAs, polos, disciplina (PJI240 – Projeto Integrador em Computação II), tutora, turma | 1 pessoa |
| 0:40–2:10 | Apresentação do problema | Quem é a comunidade (negócio de bolos caseiros da Sra. Michele), como os pedidos eram controlados (mensagens e cadernos), as dores (sobrecarga, esquecimentos, horários), a pergunta norteadora e a relação com o tema da Univesp (software web com banco de dados, API, nuvem, acessibilidade, testes) | 1 pessoa |
| 2:10–6:10 | Apresentação da solução **em funcionamento** | Demonstração ao vivo, roteiro abaixo | quem desenvolveu |
| 6:10–7:10 | Implementação na comunidade | **[PREENCHER]** Como e quando foi apresentado à Sra. Michele, o que ela achou, ajustes feitos, impacto esperado. Só dizer o que realmente aconteceu | 1 pessoa |
| 7:10–7:50 | Recursos técnicos | Slide com a arquitetura (Phoenix, PostgreSQL, LiveView, API, Docker/Oracle), 95 testes, acessibilidade verificada, git | quem desenvolveu |
| 7:50–8:20 | Fechamento | Resultados, limitações, trabalhos futuros, agradecimentos | 1 pessoa |

## Demonstração (4 minutos)

Prepare antes: sistema rodando, 4 produtos cadastrados, dados de demonstração recentes (`mix run priv/repo/demo.exs`, para as datas não aparecerem como atrasadas), `SHOP_PHONE` configurado,
duas janelas lado a lado (cliente à esquerda, painel à direita).

1. **Cardápio** (`/`): mostrar os produtos e adicionar dois bolos e brigadeiros. Mostrar o total mudando.
2. **Fazer a encomenda**: preencher nome, telefone e data de entrega. Mostrar também um erro de propósito
   (carrinho vazio ou data no passado) para evidenciar as validações.
3. **Confirmação**: mostrar a página do pedido com status *Pendente*.
4. **Painel** (`/admin/pedidos`, pedir senha): o pedido já aparece **sem recarregar** no grupo *Pendente*, com o total do grupo atualizado.
5. **Mudar status**: mostrar também a busca (digitar um nome) e clicar em *Iniciar produção*; o aviso confirma a mudança. Na janela do cliente, o status muda sozinho.
   Este é o ponto mais forte da demonstração.
6. **WhatsApp**: clicar no link do cliente (apenas mostrar que abre a conversa com a mensagem já citando o número do pedido).
7. **Produtos** (`/admin/produtos`): cadastrar ou editar um produto e mostrar que aparece no cardápio.
8. **Relatórios** (`/admin/relatorios`): faturamento, ticket médio, mais vendidos e **baixar o CSV**.
9. **API** (30 s, opcional): abrir `/api/products` no navegador para mostrar o JSON.
10. **Acessibilidade** (30 s): navegar pelo cardápio só com Tab, mostrar o link "Ir para o conteúdo" e
    o tema escuro.

## Dicas de gravação

- Gravar com OBS Studio (tela + microfone) ou o Google Meet/Teams gravando a reunião do grupo.
- Resolução 1080p, fonte do navegador ampliada (Ctrl + `+`) para a legibilidade.
- Áudio claro importa mais que imagem. Faça um teste de 20 segundos antes.
- Mostre o rosto ou o nome de cada integrante ao falar, para atender a identificação do grupo.
- Cronometre um ensaio: se passar de 9:30, corte a parte da API.

## Publicação

1. Enviar ao YouTube, com visibilidade **Não listado** (qualquer pessoa com o link assiste).
2. Título sugerido: `Encomendei – Projeto Integrador II – PJI240 Grupo 5`.
3. Colar o link na **capa do relatório** e na tarefa de vídeo do AVA.
4. Conferir o link em uma janela anônima antes de enviar.

## Antes de entregar

- [ ] Preencher a seção 3.4 do relatório e o bloco "Implementação na comunidade".
- [ ] Trocar todos os trechos amarelos `[ ... ]` do relatório.
- [ ] Gerar o PDF final a partir do Word e conferir o link do vídeo na capa.
- [ ] Anexar o PDF na tarefa de relatório e clicar em **Enviar tarefa** (o rascunho salvo não conta como enviado).
- [ ] Enviar também a **Avaliação Colaborativa** (tarefa Q7).
- [ ] Confirmar o prazo de carência com a tutora, pois as tarefas constam como atrasadas no AVA.
