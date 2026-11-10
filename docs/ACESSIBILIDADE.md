# Acessibilidade

## Recursos implementados

- Idioma da página declarado (`lang="pt-BR"`) e títulos por página.
- Link "Ir para o conteúdo" (aparece ao focar com Tab) e landmarks `header`, `nav` e `main`.
- Estrutura de títulos (h1 → h2 → h3) e listas semânticas para produtos e itens.
- Todos os campos com `label` associado; `autocomplete` em nome e telefone.
- Botões só com ícone ou símbolo têm nome acessível (`aria-label`): "Adicionar um Bolo de Limão", "Tema escuro".
- Regiões `aria-live` para quantidade, total do carrinho e status do pedido (leitor de tela anuncia mudanças).
- Mensagens de erro do formulário com `role="alert"`.
- Tabela do pedido com `caption` e `scope` nos cabeçalhos.
- Tema claro e escuro, com opção de seguir o sistema.
- Interface responsiva e utilizável só com teclado.

## Verificação automatizada

Auditoria com axe-core 4.10 (regras WCAG 2.0/2.1 A e AA e boas práticas), em Chrome headless,
nas telas `/`, `/pedido/:id`, `/admin/pedidos`, `/admin/produtos` e `/admin/produtos/new`,
nos temas claro e escuro.

| Situação | Violações |
|---|---|
| Primeira execução | 2 tipos: botões do seletor de tema sem nome (crítico) e contraste dos rótulos (sério) |
| Após correções | 0 em todas as telas e temas |
| Após o redesenho da interface | contraste em cabeçalhos de tabela e etiquetas de aviso (tema claro): corrigido, 0 violações em 6 telas nos dois temas |

Correções: `aria-label` nos três botões do seletor de tema; rótulos de campo com a cor de texto
plena em vez da versão semitransparente do tema.

Limite: ferramentas automáticas detectam só parte dos problemas. Recomenda-se complementar com
teste manual de teclado e com um leitor de tela (NVDA ou Orca).
