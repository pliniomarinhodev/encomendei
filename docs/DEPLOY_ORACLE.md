# Deploy na Oracle Cloud (Always Free)

Passo a passo para publicar o Encomendei numa VM gratuita da Oracle Cloud.
A conta e o cartão de verificação são feitos por você no site da Oracle.

## 1. Criar a VM

1. Em **Compute → Instances → Create instance**, escolha:
   - Imagem: **Ubuntu 24.04** (ou Oracle Linux)
   - Shape: **VM.Standard.A1.Flex** (Ampere ARM), 1–2 OCPU e 6–12 GB de RAM (dentro do free tier)
   - Marque **Always Free eligible**
2. Gere e **baixe a chave SSH** quando o assistente pedir.
3. Se aparecer *Out of capacity*, tente outro domínio de disponibilidade ou outro horário.

## 2. Liberar as portas 80 e 443

- Na VCN da instância: **Security List → Add Ingress Rules** para `0.0.0.0/0`, TCP, portas **80** e **443**.
- Dentro da VM (Ubuntu da Oracle traz regras de iptables que bloqueiam):

```bash
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

## 3. Nome de domínio gratuito

Crie um subdomínio em [duckdns.org](https://www.duckdns.org) apontando para o IP público da VM
(ex.: `encomendei.duckdns.org`). O Caddy só emite o certificado HTTPS se o nome apontar para a VM.

## 4. Instalar Docker na VM

```bash
ssh -i chave.key ubuntu@IP_DA_VM
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER   # saia e entre de novo no SSH
```

## 5. Subir o sistema

```bash
git clone <URL-DO-REPOSITORIO> encomendei && cd encomendei
cp .env.example .env
nano .env        # preencha PHX_HOST, senhas e SECRET_KEY_BASE
```

Para gerar o `SECRET_KEY_BASE` sem ter Elixir na VM:

```bash
openssl rand -base64 64 | tr -d '\n'
```

Depois:

```bash
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
docker compose -f docker-compose.prod.yml logs -f app
```

O primeiro build na VM ARM leva alguns minutos. As migrações rodam sozinhas a cada subida.
Acesse `https://SEU_DOMINIO/`. O painel fica em `/admin/pedidos` (usuário e senha do `.env`).

## 6. Dados iniciais

Cadastre os produtos pelo painel em `/admin/produtos`.

## Atualizar a versão

```bash
git pull
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

## Backup do banco

```bash
docker compose -f docker-compose.prod.yml exec db pg_dump -U postgres encomendei_prod > backup.sql
```

## Problemas comuns

| Sintoma | Causa provável |
|---|---|
| Site não abre | Porta 80/443 não liberada na Security List ou no iptables |
| Erro de certificado | `PHX_HOST` não aponta para o IP da VM |
| App reinicia sem parar | `SECRET_KEY_BASE`, `ADMIN_USER` ou `ADMIN_PASSWORD` ausentes no `.env` |
| VM sumiu depois de dias | A Oracle pode recuperar instâncias Always Free ociosas; recrie e restaure o backup |
