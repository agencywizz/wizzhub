# WizzDesk — Contexto para Codex
> Gerado por Claude em Apr 19 2026. Atualizar via /sync no Cérebro ao fim de cada sessão.
> AVISO: Este arquivo é a fonte de verdade para o Codex. Não editar manualmente.

---

## O que é este projeto

**WizzDesk** é um fork do [EVO CRM Community](https://github.com/EvolutionAPI/evo-crm-community) — central de atendimento AI com CRM, chat multi-canal, chatbots e WhatsApp. É o produto de suporte ao cliente do ecossistema Wizz! comms., vendido como SaaS nos tiers Agency e Scale.

Fork original: `EvolutionAPI/evo-crm-community`
Repo Wizz: `agencywizz/wizzdesk`

---

## Dono

| Campo | Valor |
|-------|-------|
| Nome | Junior Dameto |
| Empresa | Wizz! comms. (nunca Agency Wizz, nunca wIZZ!) |
| Site | wizzcomms.com |
| Subdomínio produto | desk.wizzcomms.com |
| Email (suporte) | support@wizzcomms.com |
| Git author | agencywizz / wizzdigitalagency@gmail.com |

---

## Stack

```
evo-auth-service     → Ruby 3.4 / Rails 7.1   — Auth, RBAC, OAuth2       (port 3001)
evo-ai-crm           → Ruby 3.4 / Rails 7.1   — CRM, conversas, inboxes  (port 3000)
evo-ai-frontend      → React / TypeScript / Vite — Interface web          (port 5173)
evo-ai-processor     → Python 3.10 / FastAPI   — AI agent execution       (port 8000)
evo-ai-core-service  → Go / Gin                — Gestão de agentes        (port 5555)
evo-bot-runtime      → Go / Gin                — Bot pipeline, dispatch   (port 8080)
evolution-api        → Node.js                 — WhatsApp integration
evolution-go         → Go                      — WhatsApp (Go impl.)

Infra: PostgreSQL (pgvector) + Redis
Orquestração: Docker Compose (submodules por serviço)
```

**IMPORTANTE — Submodules:**
Os serviços são Git submodules ainda não inicializados. Antes de qualquer desenvolvimento:
```bash
git submodule update --init --recursive
```

---

## Design System — Wizz! comms.

**Mesmo sistema do WizzOS — sem cor secundária.**

### Cores
```css
--bg:        #0D0D0D;   /* background */
--surface:   #1A1A1A;   /* cards, containers */
--accent:    #FF4500;   /* Wizz Orange */
--hover:     #CC3700;   /* Deep Orange */
--text:      #F0F0F0;   /* body text */
--muted:     #666666;   /* texto secundário */
```

### Tipografia
```css
font-family: 'Space Grotesk', sans-serif;
/* Google Fonts: https://fonts.google.com/specimen/Space+Grotesk */
/* Pesos: 300, 400, 500, 600, 700 */
```

### Logos (fonte: /Users/juniordameto/Documents/projects/trabalhos/wizzbranding/logos/)
| Variante | Arquivo fonte | Destino no repo |
|----------|--------------|-----------------|
| Navbar / header | `SITE 300X80/1.png` | `public/logo.png` |
| Dark background | `SEM FUNDO/1.png` | `public/logo-dark.png` |
| Avatar / ícone | `PERFIL/1.png` | `public/logo-icon.png` |

---

## Plano de execução — Fase 1: Setup + Branding

### TAREFA 1 — Inicializar submodules
```bash
git submodule update --init --recursive
```

---

### TAREFA 2 — Copiar logos
```bash
cp "/Users/juniordameto/Documents/projects/trabalhos/wizzbranding/logos/SITE 300X80/1.png" public/logo.png
cp "/Users/juniordameto/Documents/projects/trabalhos/wizzbranding/logos/SEM FUNDO/1.png" public/logo-dark.png
cp "/Users/juniordameto/Documents/projects/trabalhos/wizzbranding/logos/PERFIL/1.png" public/logo-icon.png
```

---

### TAREFA 3 — Branding frontend (evo-ai-frontend-community)

**Arquivo principal:** `evo-ai-frontend-community/src/index.css` ou equivalente global

1. Adicionar import Space Grotesk no HTML base / `_document`
2. Substituir variáveis CSS pelos tokens Wizz (ver Design System acima)
3. Substituir logo no header/navbar pelo `public/logo.png`
4. Título da página: `<title>WizzDesk</title>`
5. Meta description: `"WizzDesk — Central de atendimento AI para o teu negócio"`

---

### TAREFA 4 — Renomear referências nos arquivos de config

Substituições globais:

| De | Para |
|----|------|
| `EVO CRM` / `Evo CRM` / `evo-crm` | `WizzDesk` |
| `Evolution Foundation` | `Wizz! comms.` |
| `evolutionfoundation.com.br` | `wizzcomms.com` |
| `ORGANIZATION_NAME="Evo AI"` | `ORGANIZATION_NAME="WizzDesk"` |
| `ORGANIZATION_URL="https://evoai.evoapicloud.com"` | `ORGANIZATION_URL="https://desk.wizzcomms.com"` |

**Exceções — NÃO substituir:**
- Nomes internos de serviços Docker (`evo-auth`, `evo-crm`, `evo-core`) — são identificadores técnicos
- Referências a `Evolution API` (produto externo de WhatsApp)
- Conteúdo de `.git/`
- Arquivo `NOTICE` (créditos de licença)

---

### TAREFA 5 — Commit inicial na branch wizz

```bash
git add -A
git commit -m "chore: initial wizzdesk branding from evo-crm-community"
# branch wizz já existe (criada antes do Codex)
```

---

## Plano de execução — Fase 2: Multi-tenancy

**Objectivo:** uma única stack Docker serve N clientes, cada um isolado por `account_id`.

### Estratégia: Row-level isolation com `acts_as_tenant`

**Porquê esta abordagem:**
- Mesmo modelo que o WizzHub original usava (Next.js + Supabase RLS)
- Uma instância Rails serve todos os clientes
- Zero overhead de containers por cliente
- Escala até 50+ clientes no KVM 2/4

### TAREFA 6 — Adicionar acts_as_tenant (evo-ai-crm-community)

**Arquivo:** `evo-ai-crm-community/Gemfile`
```ruby
gem 'acts_as_tenant'
```

**Modelo de tenant:** usar o modelo `Account` já existente no CRM (cada conta = um cliente).

**Passos:**
1. Adicionar gem ao Gemfile
2. Criar migration: adicionar `account_id` a todas as tabelas que não têm (conversations, contacts, inboxes, etc.)
3. Adicionar `acts_as_tenant(:account)` nos models principais
4. Middleware de resolução de tenant por subdomínio:
   - `client1.desk.wizzcomms.com` → resolve para Account `client1`
   - Fallback: header `X-Account-ID` para API calls
5. Seed: criar conta demo para testes

**Arquivo:** `evo-ai-crm-community/config/application.rb`
```ruby
require 'acts_as_tenant'
```

**Arquivo:** `evo-ai-crm-community/app/controllers/application_controller.rb`
```ruby
set_current_tenant_through_filter
before_action :find_tenant

def find_tenant
  current_account = Account.find_by(subdomain: request.subdomain)
  set_current_tenant(current_account)
end
```

---

## Plano de execução — Fase 3: Stripe Billing

**Objectivo:** cliente escolhe plano → paga no Stripe → org provisionada automaticamente.

### Tiers e preços

| Plano | Preço/mês (cliente paga) | Stripe recebe | Wizz recebe |
|-------|--------------------------|---------------|-------------|
| Agency | €80 | ~€1,45 | ~€78,55 |
| Scale | €200 | ~€3,25 | ~€196,75 |
| WizzDesk Solo | €40 | ~€0,85 | ~€39,15 |

*(taxa EU: 1,5% + €0,25)*

### TAREFA 7 — Webhook de provisionamento (no WizzOS)

Fluxo:
```
Cliente paga Stripe
→ Webhook POST /api/billing/webhook (WizzOS dashboard)
→ WizzOS verifica evento `checkout.session.completed`
→ Cria Account no WizzDesk via API: POST /api/v1/accounts
→ Cria subdomínio: client-slug.desk.wizzcomms.com (Cloudflare API)
→ Envia email de boas-vindas (Resend)
```

**Variáveis necessárias no WizzOS .env:**
```env
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
WIZZDESK_API_URL=https://desk.wizzcomms.com
WIZZDESK_API_TOKEN=...
CLOUDFLARE_API_TOKEN=...
CLOUDFLARE_ZONE_ID=...
```

---

## Deploy VPS — Fase 4

### Pré-requisitos no VPS
- Traefik já rodando (com Cloudflare DNS challenge) ✅
- Docker Swarm ou Docker Compose
- Wildcard DNS: `*.desk.wizzcomms.com → IP do VPS` (configurar no Cloudflare)

### Serviços a manter no VPS (estado final)
```
traefik          → proxy SSL (já activo)
wizzos           → app.wizzcomms.com
wizzdesk         → desk.wizzcomms.com + *.desk.wizzcomms.com
```
> n8n e evolutionapi serão removidos quando WizzOS cobrir as suas funções.

### Labels Traefik para WizzDesk frontend
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.wizzdesk.rule=Host(`desk.wizzcomms.com`) || HostRegexp(`{subdomain:[a-z0-9-]+}.desk.wizzcomms.com`)"
  - "traefik.http.routers.wizzdesk.tls.certresolver=le"
  - "traefik.http.services.wizzdesk.loadbalancer.server.port=5173"
```

---

## Integração com WizzOS

Após deploy, configurar no `.env` do WizzOS:
```env
EVO_CRM_URL=https://desk.wizzcomms.com
EVO_CRM_TOKEN=<token gerado no WizzDesk admin>
```

Os agentes `zara-cs`, `dex-data` e a skill `cs-draft-response` no WizzOS ficam automaticamente ligados ao WizzDesk.

---

## Estado actual

### O que existe
- ✅ Repo clonado em `/trabalhos/wizzdesk/`
- ✅ Branch `wizz` criada
- ✅ Upstream configurado (`EvolutionAPI/evo-crm-community`)
- ⬜ Submodules inicializados
- ⬜ Branding Wizz aplicado
- ⬜ Multi-tenancy (acts_as_tenant)
- ⬜ Stripe + provisionamento
- ⬜ Deploy VPS

### O que falta
- [ ] Fase 1: submodules + branding + commit wizz
- [ ] Fase 2: acts_as_tenant + migrations + middleware de tenant
- [ ] Fase 3: Stripe + webhook provisionamento no WizzOS
- [ ] Fase 4: deploy VPS + wildcard DNS Cloudflare

---

## Convenções de código (todos os projetos Wizz)

- Git author: `user.name=agencywizz` / `user.email=wizzdigitalagency@gmail.com`
- Commits: conventional commits (`feat:`, `fix:`, `chore:`)
- Secrets: sempre em `.env`, nunca hardcoded
- Ruby: seguir convenções Rails (snake_case, MVC)
- SQL: sempre queries parametrizadas (ActiveRecord previne injection por padrão)
