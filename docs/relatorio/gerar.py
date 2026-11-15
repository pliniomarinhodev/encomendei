import re, base64, html as H
M = lambda t: f'<mark>[{t}]</mark>'

resumo = ("Este relatório apresenta o desenvolvimento do Encomendei, uma aplicação web para automação de encomendas de uma pequena confeitaria familiar que produz bolos caseiros, realizado no Projeto Integrador em Computação II da Univesp. O problema identificado foi a sobrecarga da empreendedora, que controlava pedidos por mensagens e cadernos, com falhas de comunicação e dificuldade para organizar os horários de entrega. A metodologia seguiu os pilares da Univesp (ouvir, criar e implementar) e o Design Thinking, com entrevistas, levantamento de requisitos, modelagem do banco de dados e prototipação. A solução foi construída com Elixir e Phoenix, banco de dados PostgreSQL, JavaScript por meio do Phoenix LiveView, API JSON, controle de versão com git e testes automatizados, e está publicada em nuvem, no serviço Render (plano gratuito). O sistema oferece cardápio e carrinho para o cliente, painel de pedidos atualizado em tempo real para a empreendedora e relatórios de vendas. A acessibilidade foi verificada com a ferramenta axe-core, sem violações nas telas avaliadas. O resultado é uma solução funcional que substitui o controle manual por um fluxo organizado de pedidos, com preço calculado no servidor e acompanhamento do status. "
          + M("PREENCHER: uma frase com o resultado da validação com a usuária"))
palavras = len(re.sub(r'<[^>]+>','',resumo).split())

FOTOS = "fotos ilustrativas do Wikimedia Commons: Pedro Toniazzo Terres (CC BY-SA 4.0), Wilfredor (CC0), Andy Li (CC0) e Rodrigogomesonetwo (CC BY-SA 4.0)"

def fig(n, arq, legenda, w=11, fonte="Autores (2026)"):
    return f'<p class="fig"><b>Figura {n}</b> – {legenda}</p><p class="img"><img src="data:image/png;base64,{base64.b64encode(open(arq,'rb').read()).decode()}" width="{int(w*37.8)}"></p><p class="fonte">Fonte: {fonte}</p>'

def tabela(cab, linhas, legenda=None):
    t = ''
    if legenda: t += f'<p class="fig"><b>{legenda}</b></p>'
    t += '<table><tr>' + ''.join(f'<th>{c}</th>' for c in cab) + '</tr>'
    for l in linhas: t += '<tr>' + ''.join(f'<td>{c}</td>' for c in l) + '</tr>'
    return t + '</table><p class="fonte">Fonte: Autores (2026)</p>'

corpo = f'''
<div class="capa">
<p class="c">UNIVERSIDADE VIRTUAL DO ESTADO DE SÃO PAULO</p>
<br><br>
<p class="c">Danilo Henrique Scateloni – RA 24221054<br>Fernando Donizeti Abachi – RA 24209928<br>Paulo Patrick Rodrigues Martins – RA 24223460<br>Plinio Henrique Sgobi Marinho – RA 24202364</p>
<br><br><br>
<p class="c"><b>ENCOMENDEI: APLICAÇÃO WEB PARA AUTOMAÇÃO DE ENCOMENDAS DE CONFEITARIA</b></p>
<br><br>
<p class="c">Vídeo de apresentação: {M("COLAR AQUI O LINK DO YOUTUBE")}</p>
<p class="c">Link para acesso no GitHub: https://github.com/pliniomarinhodev/encomendei</p>
<br><br><br>
<p class="c">Vinhedo – SP<br>2026</p>
</div>
<p class="pb"></p>

<p class="c">UNIVERSIDADE VIRTUAL DO ESTADO DE SÃO PAULO</p>
<p class="c"><b>ENCOMENDEI: APLICAÇÃO WEB PARA AUTOMAÇÃO DE ENCOMENDAS DE CONFEITARIA</b></p>
<p class="rec">Relatório Técnico-Científico apresentado na disciplina de Projeto Integrador em Computação II para o curso do Eixo de Computação da Universidade Virtual do Estado de São Paulo (UNIVESP).<br>Tutora: Elaine Cecilia Gomes Macagnan.</p>
<p class="c">Vinhedo – SP<br>2026</p>
<p class="pb"></p>

<p class="rec">SCATELONI, Danilo Henrique; ABACHI, Fernando Donizeti; MARTINS, Paulo Patrick Rodrigues; MARINHO, Plinio Henrique Sgobi. <b>Encomendei: aplicação web para automação de encomendas de confeitaria</b>. Relatório Técnico-Científico. Eixo de Computação – Universidade Virtual do Estado de São Paulo. Tutora: Elaine Cecilia Gomes Macagnan. Polo: {M("CONFIRMAR o polo")}. 2026.</p>
<p class="pb"></p>

<h2 class="sem">RESUMO</h2>
<p>{resumo}</p>
<p><b>PALAVRAS-CHAVE:</b> Automação; Aplicação Web; Gestão de Encomendas; Phoenix LiveView; Acessibilidade.</p>
<p class="pb"></p>

<h2 class="sem">LISTA DE FIGURAS</h2>
<p class="sum">Figura 1 – Cardápio com fotos, carrinho e formulário de encomenda do cliente<br>
Figura 2 – Confirmação do pedido com andamento em tempo real<br>
Figura 3 – Painel de pedidos da empreendedora, agrupado por status<br>
Figura 4 – Relatórios de vendas<br>
Figura 5 – Cardápio com barra do carrinho e painel de pedidos no celular<br>
Figura 6 – Diagrama das tabelas do banco de dados e seus relacionamentos</p>
<p class="pb"></p>

<h2 class="sem">SUMÁRIO</h2>
<p class="sum">1 INTRODUÇÃO<br>
2 DESENVOLVIMENTO<br>
&nbsp;&nbsp;2.1 Objetivos gerais<br>
&nbsp;&nbsp;2.2 Objetivos específicos<br>
&nbsp;&nbsp;2.3 Justificativa, delimitação do problema e relação com o tema norteador<br>
&nbsp;&nbsp;2.4 Análise de sistemas semelhantes<br>
&nbsp;&nbsp;2.5 Fundamentação teórica<br>
&nbsp;&nbsp;2.6 Aplicação das disciplinas estudadas no projeto integrador<br>
3 METODOLOGIA<br>
&nbsp;&nbsp;3.1 Etapas Ouvir, Criar e Implementar<br>
&nbsp;&nbsp;3.2 Escolha das tecnologias<br>
4 RESULTADOS E SOLUÇÃO FINAL<br>
&nbsp;&nbsp;4.1 A solução desenvolvida<br>
&nbsp;&nbsp;4.2 Etapas de construção<br>
&nbsp;&nbsp;4.3 Verificação: testes e acessibilidade<br>
&nbsp;&nbsp;4.4 Implantação e validação com a usuária<br>
&nbsp;&nbsp;4.5 Limitações<br>
5 CONSIDERAÇÕES FINAIS<br>
REFERÊNCIAS</p>
<p class="pb"></p>

<h1>1 INTRODUÇÃO</h1>
<p>Pequenos negócios familiares costumam gerenciar seus pedidos de forma manual, por mensagens de aplicativos e cadernos de anotações. Esse modelo funciona enquanto o volume é baixo, mas passa a gerar esquecimentos, conflitos de horário e sobrecarga de quem produz e atende ao mesmo tempo. Neste trabalho, o grupo aborda esse problema em um negócio caseiro de produção e venda de bolos, comunidade externa escolhida para o Projeto Integrador.</p>
<p>A proposta foi desenvolver uma aplicação web, chamada Encomendei, na qual o cliente consulta o cardápio e envia sua encomenda, e a empreendedora acompanha a fila de produção em um painel. O relatório descreve o problema, os fundamentos e a metodologia adotados, a solução construída e a forma como ela foi verificada.</p>

<h1>2 DESENVOLVIMENTO</h1>
<h2>2.1 Objetivos gerais</h2>
<p>desenvolver uma aplicação web integrada a um banco de dados para a gestão de encomendas de uma confeitaria de bolos caseiros, reduzindo falhas de comunicação e substituindo o controle manual por um processo organizado.</p>

<h2>2.2 Objetivos específicos</h2>
<ul>
<li>levantar os requisitos junto à empreendedora (comunidade externa);</li>
<li>modelar o banco de dados de clientes, produtos e pedidos;</li>
<li>implementar cardápio e carrinho de compras para os clientes;</li>
<li>implementar painel de gestão do status dos pedidos (pendente, em produção, entregue);</li>
<li>disponibilizar relatórios de vendas para apoiar a gestão do negócio;</li>
<li>garantir acessibilidade, testes automatizados e controle de versão;</li>
<li>validar a solução com a usuária final.</li>
</ul>

<h2>2.3 Justificativa, delimitação do problema e relação com o tema norteador</h2>
<p>Antes de escolher o negócio de bolos, o grupo considerou outras comunidades, como uma papelaria e uma mercearia do bairro, que também sofrem com o controle de estoque. Essas opções foram descartadas pela dificuldade de conciliar horários de entrevistas e pela menor abertura dos proprietários para testar novas tecnologias. A indicação do negócio de bolos veio de um dos integrantes, cuja família mantém a atividade, o que facilitou o acesso e o contato frequente com a usuária.</p>
<p>No primeiro contato com a Sra. Michele, no local onde os bolos são produzidos, o grupo observou um ambiente organizado, mas com forte carga mental decorrente de anotar pedidos no papel e acompanhar dezenas de mensagens. A pergunta norteadora do projeto foi: <i>como o desenvolvimento de uma aplicação web com banco de dados pode contribuir para reduzir a sobrecarga e melhorar a gestão de encomendas em um pequeno negócio de bolos caseiros?</i></p>
<p>O problema se relaciona ao tema norteador da Univesp para o semestre, que propõe o desenvolvimento de um software com framework web que utilize banco de dados, script web, nuvem, uso de API, acessibilidade, controle de versão e testes, com análise de dados opcional {M("CONFERIR o texto exato do tema norteador no Plano de Ensino")}. O Encomendei atende a todos esses elementos, como mostra a seção 4.1.</p>

<h2>2.4 Análise de sistemas semelhantes</h2>
<p>Antes de definir a interface, o grupo pesquisou soluções existentes para pedidos online e para encomendas de confeitaria, em páginas dos próprios fornecedores, em publicações sobre o setor e em trabalhos acadêmicos. A consulta foi feita em novembro de 2026 e não substitui uma avaliação com as versões de teste de cada produto.</p>
<p>As plataformas brasileiras de cardápio digital mais conhecidas, como o Anota AI e o Cardápio Web, são voltadas a restaurantes e delivery: oferecem cardápio digital, QR Code, atendimento automatizado pelo WhatsApp e integração com meios de pagamento (ANOTA AI, [s.d.]; GIRONEWS, [s.d.]). Em uma reclamação pública, um cliente de fábrica de salgados afirmou que o Anota AI parecia pensado apenas para hamburguerias e pizzarias (RECLAME AQUI, [s.d.]), o que sugere que o foco no pedido imediato serve mal à produção sob encomenda. Já os sistemas específicos para confeitaria, como o BakeSmart e o UpMenu, tratam pedidos antecipados e personalizados, agenda de produção, cadastro de clientes com histórico e acompanhamento do pedido (BAKESMART, [s.d.]; UPMENU, [s.d.]), mas em geral são pagos em dólar, o que pesa para uma confeiteira que trabalha sozinha. Há ainda trabalhos acadêmicos de sistemas web de encomendas para confeitarias (UTFPR, [s.d.]; ETEC, [s.d.]), o que confirma a demanda, embora sejam soluções sob medida, sem uso por outros negócios.</p>
<p>Sobre a experiência de compra, guias do setor de pedidos online recomendam compra sem criar conta, carrinho sempre visível, botões de toque com pelo menos 44 pixels e leitura em uma coluna no celular (CHOWBUS, [s.d.]). O quadro a seguir compara os achados com o Encomendei.</p>
{tabela(["Característica","Cardápio digital para delivery","Software de confeitaria","Encomendei"],[
 ["Foco","Restaurante e entrega imediata","Confeitaria, com pedido personalizado","Encomenda de bolos com data de entrega"],
 ["Custo","Mensalidade em reais","Mensalidade em dólar","Gratuito (código aberto e hospedagem gratuita)"],
 ["Compra sem criar conta","Sim","Em geral sim","Sim"],
 ["Data e hora da entrega no pedido","Pouco explorada","Sim","Sim, com validação de data futura"],
 ["Acompanhamento pelo cliente","Em geral sim","Sim","Sim, em tempo real, por número e telefone"],
 ["Painel por etapa de produção","Fila de cozinha","Agenda de produção","Painel por status, com atrasadas e entregas de hoje"],
 ["Pagamento online","Sim","Sim","Não (fora do escopo)"],
 ["Atendimento automático por WhatsApp","Sim (chatbot)","Em geral não","Não; link com mensagem pronta"]],
 "Tabela 1 – Comparação entre soluções semelhantes e o Encomendei")}
<p>A pesquisa orientou três decisões: manter a compra sem cadastro, com carrinho fixo e botões grandes no celular; incluir data de entrega obrigatória no pedido e um painel por etapa, que as soluções de delivery não priorizam; e dar ao cliente um caminho simples para reencontrar o pedido, sem conta. O pagamento online e o atendimento automático foram deixados como trabalho futuro, pelo custo e pela complexidade de manter.</p>

<h2>2.5 Fundamentação teórica</h2>
<p>Segundo Laudon e Laudon (2014), os sistemas de informação coletam, processam e armazenam dados para apoiar a tomada de decisão. Em pequenos empreendimentos, o uso de registros informais gera falhas e retrabalho, e a organização e o planejamento exigem ferramentas adequadas ao controle dos processos (OLIVEIRA, 2023).</p>
<p>As aplicações web podem ser acessadas por diferentes dispositivos conectados à internet, o que dá flexibilidade ao usuário (MACIEL, 2020). O desenvolvimento ágil dessas aplicações costuma apoiar-se em frameworks (PRESSMAN; MAXIM, 2016). O armazenamento organizado de cadastros e pedidos é feito, em geral, por bancos de dados relacionais, que garantem consistência por meio de chaves e restrições (ELMASRI; NAVATHE, 2011).</p>
<p>No processo de construção, a engenharia de software recomenda levantar requisitos junto aos usuários, verificar o sistema com testes e controlar as versões do código (SOMMERVILLE, 2019; PRESSMAN; MAXIM, 2016). Para entender as necessidades reais da usuária, o grupo adotou o Design Thinking, abordagem centrada no usuário que alterna compreensão do contexto, ideação e prototipação (CAVALCANTI; FILATRO, 2020).</p>
<p>Quanto à acessibilidade, as Diretrizes de Acessibilidade para Conteúdo Web (WCAG) 2.1 organizam as exigências em quatro princípios: perceptível, operável, compreensível e robusto (W3C, 2018). Esses princípios orientaram as decisões de interface do sistema, como rótulos em todos os campos, contraste de cores, navegação por teclado e avisos dinâmicos para leitores de tela.</p>
<p>Por fim, o framework Phoenix, escrito em Elixir, permite construir interfaces que se atualizam em tempo real pelo componente LiveView, sem exigir uma aplicação de front-end separada (PHOENIX FRAMEWORK, [s.d.]). O Elixir executa sobre a máquina virtual do Erlang, projetada para sistemas concorrentes e tolerantes a falhas (ELIXIR, [s.d.]).</p>

<h2>2.6 Aplicação das disciplinas estudadas no projeto integrador</h2>
<p>{M("CONFERIR quais disciplinas o grupo já cursou e ajustar a lista")}</p>
<ul>
<li><b>Banco de Dados:</b> modelagem entidade-relacionamento, chaves estrangeiras, normalização e consultas SQL usadas nos relatórios.</li>
<li><b>Desenvolvimento Web:</b> HTML semântico, CSS, JavaScript, protocolo HTTP e criação de APIs.</li>
<li><b>Engenharia de Software:</b> levantamento de requisitos, testes, controle de versão e documentação.</li>
<li><b>Introdução à Ciência de Dados:</b> organização de dados de vendas e construção de indicadores, como faturamento e ranking de produtos.</li>
<li><b>Modelagem e Inferência Estatística:</b> medidas descritivas utilizadas nos relatórios, como média (ticket médio) e totais por período.</li>
<li><b>Projeto Integrador em Computação I:</b> método de trabalho em grupo e elaboração do plano de ação.</li>
</ul>

<h1>3 METODOLOGIA</h1>
<h2>3.1 Etapas Ouvir, Criar e Implementar</h2>
<p>O trabalho seguiu os pilares propostos pela Univesp:</p>
<p><b>Ouvir e interpretar o contexto.</b> Entrevistas informais e observação da rotina da Sra. Michele no local de trabalho. Identificou-se que a ausência de um histórico organizado de pedidos era o maior gargalo.</p>
<p><b>Criar e prototipar.</b> Sessões de ideação em grupo, definição dos requisitos funcionais, modelagem inicial do banco de dados (clientes, produtos e pedidos) e esboços das telas, apresentados no relatório parcial.</p>
<p><b>Implementar e testar.</b> Codificação em ciclos curtos, com versionamento em git, testes automatizados a cada funcionalidade e verificação de acessibilidade com ferramenta automática.</p>
<h2>3.2 Escolha das tecnologias</h2>
<p>O relatório parcial citava Django (Python) e JavaScript/Node como possibilidades. Ao iniciar a implementação, o grupo optou por Elixir com Phoenix {M("CONFIRMAR com o grupo o motivo da decisão")}. A Tabela 1 resume a comparação feita.</p>
{tabela(["Alternativa","Vantagens","Pontos de atenção"],[
 ["Django (Python)","Muito documentado, painel administrativo pronto, boa base de referências","Atualização em tempo real do painel exigiria componente extra (WebSocket)"],
 ["Node.js com Express","Mesma linguagem no servidor e no navegador","Exige montar manualmente autenticação, validação e camada de dados"],
 ["Elixir com Phoenix (escolhida)","LiveView atualiza o painel em tempo real sem front-end separado; testes embutidos; migrações de banco integradas","Comunidade menor; curva de aprendizado para quem não conhece a linguagem"]],
 "Tabela 2 – Alternativas de tecnologia consideradas")}

<h1>4 RESULTADOS E SOLUÇÃO FINAL</h1>
<h2>4.1 A solução desenvolvida</h2>
<p>O Encomendei tem duas visões. Na <b>visão do cliente</b>, o cardápio lista os produtos disponíveis, com foto quando a empreendedora cadastra o link da imagem; o cliente monta o carrinho, informa nome, telefone, data e hora de entrega e envia a encomenda (Figura 1); se algum dado estiver incorreto, o erro aparece junto do próprio campo, todos de uma vez. Uma barra fixa no rodapé do celular mostra a quantidade de itens e o total, com atalho para finalizar o pedido (Figura 5). Ao concluir, recebe o número do pedido (por exemplo, #42) e uma página de confirmação que acompanha o status do pedido em tempo real e traz um botão para falar com a confeiteira pelo WhatsApp (Figura 2). Quem perder a página reencontra o pedido na área "Acompanhar pedido", informando o número e o telefone usado na encomenda, sem precisar de conta. Na <b>visão da empreendedora</b>, um painel protegido por login (usuário e senha, com sessão de 12 horas) agrupa os pedidos por status (pendente, em produção e entregue, além de um grupo de cancelados quando houver), com a contagem e o valor de cada grupo. Há busca por nome (sem diferenciar acentos), telefone ou número do pedido e filtro por data de entrega. Cada pedido pode avançar para a etapa seguinte ou ser cancelado, com confirmação, e o botão de cancelar fica separado do principal para evitar cliques por engano (Figura 3). Uma coluna lateral destaca as entregas de hoje e as atrasadas. O painel atualiza sozinho: quando chega um pedido novo, exibe um aviso e destaca a linha por alguns segundos, e cada mudança de status é confirmada na tela. No celular, cada pedido vira um cartão, sem rolagem lateral (Figura 5). O painel traz o link direto para o WhatsApp do cliente, com uma mensagem inicial que cita o número do pedido. A empreendedora também cadastra os produtos, podendo informar o link da foto, que é validado (apenas endereços http e https) e é escondido sem prejuízo se sair do ar, e marcá-los como disponíveis ou indisponíveis com um clique, e consulta relatórios de vendas, que separam o valor já entregue do que ainda falta entregar, com exportação em CSV, em que cada linha identifica o pedido pelo número (Figura 4). O número é sequencial e gerado pelo banco de dados; as regras de integridade (total e quantidade nunca negativos, status restrito aos valores válidos) são garantidas pelo próprio PostgreSQL, além de validadas na aplicação.</p>
{fig(1,"cardapio.png","Cardápio com fotos, carrinho e formulário de encomenda do cliente",11,"Autores (2026); "+FOTOS)}
{fig(2,"confirmacao.png","Confirmação do pedido com andamento em tempo real")}
{fig(3,"painel.png","Painel de pedidos da empreendedora, agrupado por status",15)}
{fig(4,"relatorios.png","Relatórios de vendas",13)}
{fig(5,"celular.png","Cardápio com barra do carrinho e painel de pedidos no celular",12,"Autores (2026); "+FOTOS)}
<p>O banco de dados relacional possui quatro tabelas: produtos, clientes, pedidos e itens de pedido, ligadas por chaves estrangeiras (Figura 6).</p>
{fig(6,"diagrama_banco.png","Diagrama das tabelas do banco de dados e seus relacionamentos",13)}
<p>As principais regras de negócio são:</p>
<ul>
<li>o preço de cada item é lido do cadastro de produtos no servidor, e o valor enviado pelo cliente é ignorado;</li>
<li>só é possível encomendar produtos disponíveis e com data de entrega futura;</li>
<li>o pedido, o cliente e os itens são gravados em uma única transação, de modo que uma falha não deixa dados incompletos;</li>
<li>o status segue um fluxo definido: pendente → em produção → entregue, com cancelamento possível até a entrega, sem retorno a etapas anteriores;</li>
<li>pedidos cancelados não entram nos valores de faturamento.</li>
</ul>
{tabela(["Requisito do Projeto Integrador","Como foi atendido"],[
 ["Framework web","Phoenix 1.8 (Elixir)"],
 ["Banco de dados","PostgreSQL, com migrações versionadas"],
 ["Script web (JavaScript)","Phoenix LiveView: carrinho e painel atualizados sem recarregar a página"],
 ["Nuvem","Publicado no Render (plano gratuito) em https://encomendei.onrender.com, a partir de imagem Docker, com HTTPS automático e banco PostgreSQL gerenciado"],
 ["Uso de API","API JSON: catálogo, criação e consulta de pedidos, rotas administrativas com autenticação"],
 ["Acessibilidade","HTML semântico, rótulos, avisos para leitor de tela, contraste e tema claro/escuro"],
 ["Controle de versão","git, com histórico de commits por funcionalidade"],
 ["Testes","124 testes automatizados (ExUnit), todos aprovados"],
 ["Análise de dados (opcional)","Relatórios de faturamento, ticket médio, produtos mais vendidos e vendas por semana, com exportação em CSV"]],
 "Tabela 3 – Requisitos do projeto e como foram atendidos")}

<h2>4.2 Etapas de construção</h2>
<p>A construção foi organizada em etapas, cada uma registrada no controle de versão: (1) criação do projeto e do esquema de banco de dados; (2) regras de negócio dos pedidos, com testes; (3) telas do cliente e painel da empreendedora em tempo real; (4) API JSON; (5) publicação em nuvem, com contêineres e documentação; (6) correções de acessibilidade; (7) relatórios de vendas e exportação.</p>

<h2>4.3 Verificação: testes e acessibilidade</h2>
<p>Os 124 testes automatizados cobrem as regras de negócio (preço calculado no servidor, produto indisponível, carrinho vazio, data passada, fluxo de status), as restrições do banco de dados (número único, valores não negativos, status válido), as telas do cliente e do painel, a proteção por senha, a API e os relatórios. Há testes para a atualização do painel em tempo real quando um pedido é criado, para a busca e o filtro de pedidos, para os erros do formulário e para o resumo de valores entregues e a entregar. A exportação CSV neutraliza campos que começam com caracteres de fórmula, evitando que planilhas executem conteúdo digitado por clientes.</p>
<p>A acessibilidade foi avaliada com a ferramenta axe-core, em navegador sem interface gráfica, nas telas do cardápio, da confirmação, do painel, do cadastro de produtos e dos relatórios, nos temas claro e escuro, em computador (1280 px) e em tela de celular (390 px). A primeira execução apontou dois problemas: botões do seletor de tema sem nome acessível e baixo contraste nos rótulos dos campos. Após o redesenho da interface, a auditoria foi repetida e apontou contraste insuficiente em cabeçalhos de tabela e em etiquetas de status do tema claro, corrigidos com ajuste da paleta. Depois, o layout foi adaptado para celular e a auditoria foi refeita também em tela de 390 px. Ao final, não restaram violações em nenhuma das telas, nos dois temas e nas duas larguras. Ferramentas automáticas detectam apenas parte dos problemas; por isso, recomenda-se complementar a verificação com testes manuais de teclado e leitor de tela {M("PREENCHER se o grupo fez teste manual")}.</p>

<h2>4.4 Implantação e validação com a usuária</h2>
<p>O sistema foi publicado na nuvem, no serviço Render (plano gratuito), e pode ser acessado em https://encomendei.onrender.com. O serviço constrói a imagem Docker do projeto a partir do repositório de código-fonte (https://github.com/pliniomarinhodev/encomendei), oferece HTTPS automático e mantém o banco de dados PostgreSQL. A primeira escolha de hospedagem foi a camada gratuita da Oracle Cloud, mas o cadastro no Brasil exige CNPJ, o que inviabilizou o uso por pessoas físicas; o projeto mantém o guia de implantação para a Oracle como alternativa.</p>
<p>{M("PREENCHER: quando o sistema foi apresentado à Sra. Michele, o que ela testou, o feedback recebido e os ajustes feitos a partir dele. Não inventar: descrever apenas o que de fato ocorreu.")}</p>

<h2>4.5 Limitações</h2>
<ul>
<li>o plano gratuito do Render suspende o site após 15 minutos sem acesso, e o primeiro acesso depois disso leva cerca de um minuto; o banco de dados gratuito expira em 30 dias, de modo que o uso contínuo exigiria um plano pago ou outra hospedagem;</li>
<li>o sistema atende uma única confeitaria, com um único usuário e senha definidos na configuração; para várias confeitarias ou vários funcionários seria necessário separar os dados por loja e criar contas de usuário (ver Considerações finais);</li>
<li>o sistema avisa a empreendedora pelo painel, e o contato com o cliente é feito por link do WhatsApp, sem envio automático de mensagens;</li>
<li>não há pagamento online; o pagamento continua sendo combinado diretamente com o cliente;</li>
<li>a acessibilidade foi verificada principalmente de forma automatizada.</li>
</ul>

<h1>5 CONSIDERAÇÕES FINAIS</h1>
<p>O projeto respondeu à pergunta norteadora ao substituir o controle manual por um sistema web que concentra as encomendas em um único lugar, mostra a fila de produção em tempo real e evita erros típicos, como preços divergentes e datas inválidas. O trabalho também permitiu ao grupo aplicar, em um caso real, conteúdos de banco de dados, desenvolvimento web, engenharia de software e análise de dados.</p>
<p>Como contribuição, o Encomendei é uma base reutilizável por outras confeitarias e pequenos negócios que vendem por encomenda. Como trabalhos futuros, sugerem-se notificações automáticas por mensagem, pagamento online e testes de acessibilidade com usuários de tecnologias assistivas.</p>
<p>A principal evolução prevista é atender várias confeitarias no mesmo sistema (multiloja). Cada confeitaria teria seu próprio cadastro de usuárias, com senha armazenada de forma criptografada, e um endereço próprio, identificado pelo nome da loja. A segurança desse modelo depende de que a identificação da loja venha sempre da usuária autenticada, e nunca do endereço ou de números enviados pelo navegador. Para isso, propõe-se: (a) um filtro por loja obrigatório em todas as consultas ao banco de dados, centralizado em um único ponto do código, de modo que uma consulta sem a loja não seja possível; (b) resposta idêntica ("não encontrado") para lojas inexistentes e para lojas de outras usuárias, a fim de não revelar quais existem; (c) canais de atualização em tempo real separados por loja, para que o painel de uma confeitaria não receba avisos de outra; (d) restrições no próprio banco de dados, como chaves estrangeiras compostas, que impeçam relacionar dados de lojas diferentes mesmo diante de um erro de programação; (e) limite de tentativas de login e uma conta de administração do sistema separada, responsável por cadastrar as lojas; e (f) testes automatizados de isolamento, que tentam acessar, com o login de uma loja, os pedidos, produtos e relatórios de outra e verificam que nenhum dado é exposto. Enquanto isso não for implementado, a alternativa é publicar uma cópia independente do sistema para cada confeitaria.</p>

<h1>REFERÊNCIAS</h1>
<p class="ref">ANOTA AI. <b>Cardápio digital Anota Ai</b>: modernize sua gestão de pedidos. [S.l.]: Saipos, [s.d.]. Disponível em: https://saipos.com/cardapio-digital/anota-ai. Acesso em: 14 nov. 2026.</p>
<p class="ref">BAKESMART. <b>Sales suite</b>: online ordering and custom cake orders. [S.l.]: BakeSmart, [s.d.]. Disponível em: https://bakesmart.com/products/sales-suite. Acesso em: 14 nov. 2026.</p>
<p class="ref">CAVALCANTI, Carolina; FILATRO, Andrea. <b>Design Thinking</b>: inovação com propósito. 2. ed. Barueri: Atlas, 2020.</p>
<p class="ref">CHOWBUS. <b>Restaurant online ordering best practices</b>. [S.l.]: Chowbus, [s.d.]. Disponível em: https://www.chowbus.com/blog/restaurant-online-ordering-best-practices. Acesso em: 14 nov. 2026.</p>
<p class="ref">ELIXIR. <b>Elixir</b>: documentação oficial. [S.l.]: Elixir Team, [s.d.]. Disponível em: https://elixir-lang.org/. Acesso em: {M("data")}.</p>
<p class="ref">ELMASRI, Ramez; NAVATHE, Shamkant B. <b>Sistemas de banco de dados</b>. 6. ed. São Paulo: Pearson, 2011.</p>
<p class="ref">ETEC. <b>Sistema web de encomendas para confeiteiros</b>. Trabalho de conclusão de curso (Análise e Desenvolvimento de Sistemas). [S.l.]: Centro Paula Souza, 2024. Disponível em: https://ric.cps.sp.gov.br/bitstream/123456789/22981/1/ads_2024_1_carolinevazbarto_larissagoncalvesferreira_sistemawebdeencomendasparaconfeiteiros.pdf. Acesso em: 14 nov. 2026.</p>
<p class="ref">GIRONEWS. <b>Melhores plataformas de cardápio digital para restaurante no Brasil</b>. [S.l.]: Gironews, [s.d.]. Disponível em: https://gironews.com/food-service/melhores-plataformas-de-cardapio-digital-para-restaurante-no-brasil/. Acesso em: 14 nov. 2026.</p>
<p class="ref">LAUDON, Kenneth C.; LAUDON, Jane P. <b>Sistemas de informação gerenciais</b>. 14. ed. São Paulo: Pearson, 2014.</p>
<p class="ref">MACIEL, Francisco de Barros. <b>Python e Django</b>: desenvolvimento web moderno e ágil. Rio de Janeiro: Alta Books, 2020.</p>
<p class="ref">OLIVEIRA, Djalma de Pinho Rebouças de. <b>Planejamento estratégico</b>: conceitos, metodologia e práticas. 35. ed. Barueri: Atlas, 2023.</p>
<p class="ref">PHOENIX FRAMEWORK. <b>Phoenix e Phoenix LiveView</b>: documentação oficial. [S.l.]: Phoenix Framework, [s.d.]. Disponível em: https://hexdocs.pm/phoenix e https://hexdocs.pm/phoenix_live_view. Acesso em: {M("data")}.</p>
<p class="ref">PRESSMAN, Roger S.; MAXIM, Bruce R. <b>Engenharia de software</b>: uma abordagem profissional. 8. ed. Porto Alegre: AMGH, 2016.</p>
<p class="ref">RECLAME AQUI. <b>Anota Ai</b>: sistema arcaico pensado apenas para hamburguerias e pizzarias. [S.l.]: Reclame Aqui, [s.d.]. Disponível em: https://www.reclameaqui.com.br/anota-ai/sistema-arcaico-pensado-apenas-para-hamburguerias-e-pizzarias_EsXiURq8ulT0mXAX/. Acesso em: 14 nov. 2026.</p>
<p class="ref">SOMMERVILLE, Ian. <b>Engenharia de software</b>. 10. ed. São Paulo: Pearson, 2019.</p>
<p class="ref">UPMENU. <b>Bakery software &amp; ordering system</b>. [S.l.]: UpMenu, [s.d.]. Disponível em: https://www.upmenu.com/bakery-software. Acesso em: 14 nov. 2026.</p>
<p class="ref">UTFPR. <b>Sistema web para confeitaria</b>. Trabalho de conclusão de curso. [S.l.]: Universidade Tecnológica Federal do Paraná, [s.d.]. Disponível em: https://riut.utfpr.edu.br/jspui/bitstream/1/28491/1/sistemawebconfeitaria.pdf. Acesso em: 14 nov. 2026.</p>
<p class="ref">W3C. <b>Web Content Accessibility Guidelines (WCAG) 2.1</b>. [S.l.]: World Wide Web Consortium, 2018. Disponível em: https://www.w3.org/TR/WCAG21/. Acesso em: {M("data")}.</p>
'''
css = '''body{font-family:"Times New Roman",serif;font-size:12pt;line-height:1.5;text-align:justify}
h1{font-size:12pt;font-weight:bold;text-transform:uppercase;margin-top:18pt}
h2{font-size:12pt;font-weight:bold;margin-top:12pt} h2.sem{text-align:center}
p.c{text-align:center} p.sum{text-align:left} p.rec{margin-left:8cm;font-size:10pt;line-height:1.15;text-align:justify}
p.fig{font-size:10pt;text-align:center;margin-bottom:2pt;page-break-after:avoid} p.img{text-align:center} p.fonte{font-size:10pt;text-align:center}
p.ref{text-align:left;line-height:1.15} p.pb{page-break-before:always;margin:0;line-height:0;font-size:1pt}
table{border-collapse:collapse;width:100%;font-size:10pt;line-height:1.15} td,th{border:1px solid #000;padding:3pt;vertical-align:top;text-align:left}
th{background:#e6e6e6} mark{background:#ffff00}'''
corpo = re.sub(r'<p class="pb"></p>\s*<(\w+)((?: class="[^"]*")?)', lambda m: f'<{m.group(1)}{m.group(2)} style="page-break-before:always"', corpo)
open('relatorio_final.html','w',encoding='utf-8').write(f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>Encomendei - Relatório Final</title><style>{css}</style></head><body>{corpo}</body></html>')
print("palavras no resumo:", palavras)
