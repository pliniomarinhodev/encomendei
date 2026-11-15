# Publicação gratuita no Render (sem CNPJ e sem cartão)

Alternativa ao guia da Oracle, que exige CNPJ para criar a conta no Brasil.
O Render roda a mesma imagem Docker e oferece um PostgreSQL gratuito.

## Limites do plano gratuito
- O app **dorme após 15 minutos sem acesso** e leva cerca de 1 minuto para acordar no primeiro acesso.
  Abra o endereço alguns minutos antes de gravar o vídeo ou de mostrar a alguém.
- O banco gratuito **expira em 30 dias**. Para uso real, migre para um plano pago ou para a Oracle (com CNPJ).

## Passo a passo
1. Crie conta em https://render.com entrando com o GitHub.
2. **New → Blueprint** e escolha o repositório do projeto. O Render lê o `render.yaml`.
3. Preencha as três variáveis pedidas:
   - `ADMIN_USER`: login do painel (por exemplo `confeiteira`)
   - `ADMIN_PASSWORD`: uma senha forte (não use `admin`)
   - `SHOP_PHONE`: WhatsApp da confeiteira com DDD, só números
4. Clique em **Apply** e espere o primeiro build (de 5 a 10 minutos).
5. O endereço é `https://encomendei.onrender.com` (ou parecido, o Render mostra). Painel: `/admin/pedidos`.

O banco começa vazio. Cadastre os produtos em `/admin/produtos`, com o link das fotos reais.
O domínio `PHX_HOST` é obtido automaticamente do Render; não precisa configurar.

## Atualizar
Basta enviar um novo commit ao repositório (`git push`); o Render publica sozinho.
