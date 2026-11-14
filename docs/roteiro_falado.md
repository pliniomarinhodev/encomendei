# Roteiro falado do vídeo (leia em voz alta, cerca de 8 minutos)

Divisão sugerida entre os quatro. Troquem os nomes como preferirem; o que importa é
**cada um aparecer e falar pelo menos uma vez** (critério de identificação do grupo).
Texto entre colchetes `[...]` é o que só o grupo sabe. Não inventem: se algo não aconteceu, digam que está previsto.

Antes de gravar: `docker start encomendei-pg`, `mix phx.server`, `mix run priv/repo/demo.exs`
e `mix run priv/repo/demo_photos.exs`. Abram duas abas: cardápio (`/`) e painel (`/admin/pedidos`, admin/admin).

---

## 1. Abertura (0:00–0:40) — Danilo, com a câmera ou o slide de título

> Olá. Somos o Grupo 5 do Projeto Integrador em Computação II, disciplina PJI240, turma A2026S2N4,
> do polo de [POLO], com a tutora Elaine Cecilia Gomes Macagnan.
> Eu sou o Danilo Henrique Scateloni, RA 24221054.
> Meus colegas são Fernando Donizeti Abachi, RA 24209928, Paulo Patrick Rodrigues Martins, RA 24223460,
> e Plinio Henrique Sgobi Marinho, RA 24202364.
> Nosso projeto se chama **Encomendei**, um sistema web de encomendas para um negócio de bolos caseiros.

## 2. O problema (0:40–2:10) — Fernando

> A comunidade que escolhemos é o negócio de bolos caseiros da Sra. Michele, que a família de um de nós conhece.
> Hoje os pedidos chegam por mensagens de WhatsApp e são anotados no papel.
> Quando visitamos o local de produção, vimos um ambiente organizado, mas com muita carga mental:
> dezenas de mensagens para acompanhar, risco de esquecer um pedido e dificuldade de organizar os horários de entrega.
> Nossa pergunta foi: **como uma aplicação web com banco de dados pode reduzir essa sobrecarga e melhorar a gestão das encomendas?**
> Isso se encaixa no tema da Univesp deste semestre: um software com framework web, banco de dados,
> script web, nuvem, API, acessibilidade, controle de versão e testes.

## 3. A solução funcionando (2:10–6:10) — Plinio, mostrando a tela

> Vou mostrar o sistema funcionando. À esquerda, a visão do cliente; à direita, a da confeiteira.

1. **Cardápio.** "Aqui o cliente vê os produtos com foto e preço. Vou adicionar dois bolos e um cento de brigadeiros; o total muda na hora."
2. **Erro de propósito.** "Se eu digitar um telefone incompleto e uma data no passado, os dois erros aparecem junto dos campos, para a cliente corrigir de uma vez."
3. **Enviar.** "Agora com os dados certos." Enviar. "Ela recebe o **número do pedido** e uma página que acompanha o andamento. Há também um botão para falar com a confeiteira pelo WhatsApp."
4. **Painel.** Ir para a aba do painel. "O pedido apareceu sozinho, sem recarregar, com um aviso e a linha destacada. Os pedidos ficam agrupados por status, com contagem e total, e uma coluna mostra atrasadas e entregas de hoje."
5. **Mudar status.** Clicar em *Iniciar produção*. "O painel confirma a mudança. E olhem a tela do cliente..." (mostrar a outra aba) "...o status mudou sozinho, em tempo real."
6. **Busca.** Digitar um nome no campo de busca. "A confeiteira também busca por nome, telefone ou número e filtra por entregas atrasadas ou de hoje."
7. **Produtos.** `/admin/produtos`. "Ela cadastra produtos, cola o link da foto e marca como indisponível com um clique quando acaba."
8. **Relatórios.** `/admin/relatorios`. "Aqui vemos o que já foi entregue e o que falta entregar, o ticket médio e os produtos mais vendidos. O botão baixa tudo em planilha."
9. **Celular** (opcional, 20 s). Abrir o DevTools em modo celular. "No celular os pedidos viram cartões e o carrinho tem uma barra fixa."

## 4. Implementação na comunidade (6:10–7:10) — Paulo

> **[PREENCHAM COM A VERDADE.]** Exemplos de como falar, conforme o que aconteceu:
> - "Apresentamos o sistema à Sra. Michele em [DATA], por [presencial/vídeo]. Ela testou [o quê] e disse [o quê]. Ajustamos [o quê]."
> - Se ainda não foi apresentado: "A apresentação à Sra. Michele está prevista para [DATA]. A solução está pronta para implantação, e o impacto esperado é reduzir esquecimentos e centralizar os pedidos."

## 5. Recursos técnicos (7:10–7:50) — Plinio ou Fernando, com um slide de arquitetura

> Usamos **Elixir e Phoenix**, com **LiveView** para a tela atualizar em tempo real, e banco **PostgreSQL**.
> Há uma **API JSON** com pedidos e produtos. O código fica no **git**, com **124 testes automatizados**,
> e a **acessibilidade** foi verificada com a ferramenta axe-core, sem violações, também no celular.
> O sistema roda em contêineres Docker, publicado na nuvem no Render, em encomendei.onrender.com.

## 6. Fechamento (7:50–8:20) — Danilo

> Em resumo, o Encomendei troca o caderno e as mensagens soltas por um fluxo organizado de pedidos.
> Como limitações, o aviso ao cliente ainda é por link de WhatsApp, sem envio automático, e as fotos dependem de links.
> Como trabalho futuro, notificações automáticas e pagamento. Agradecemos à Sra. Michele e à tutora Elaine. Obrigado!

---

## Dicas rápidas
- Gravem a tela com o **OBS Studio** ou o **Google Meet** (gravação da reunião), com o microfone ligado. Teste de 20 segundos antes.
- Resolução 1080p e zoom do navegador em 125% (Ctrl +) para ler melhor.
- Se errar, continue: o critério é conteúdo, não edição. Passou de 10 minutos? Cortem o item 9.
- Envie ao YouTube como **Não listado**, copie o link e cole na capa do relatório e na tarefa do AVA. Abra o link em janela anônima para conferir.
