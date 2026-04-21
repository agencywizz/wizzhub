#!/usr/bin/env bash
# =============================================================================
# WizzDesk — Build all service images
# Run on VPS before: docker stack deploy -c docker-stack.yml wizzdesk
# =============================================================================
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

info() { echo -e "${CYAN}[BUILD]${RESET} $1"; }
ok()   { echo -e "${GREEN}[OK]${RESET}    $1"; }

# ---------------------------------------------------------------------------
# Build args para o frontend — URLs que o browser vai chamar directamente
# ---------------------------------------------------------------------------
VITE_API_URL="https://crm.desk.wizzcomms.com"
VITE_AUTH_API_URL="https://auth.desk.wizzcomms.com"
VITE_WS_URL="https://crm.desk.wizzcomms.com"
VITE_EVOAI_API_URL="https://core.desk.wizzcomms.com"
VITE_AGENT_PROCESSOR_URL="https://crm.desk.wizzcomms.com"
VITE_TINYMCE_API_KEY="no-api-key"

info "[1/6] evo-auth..."
docker build \
  -t wizzdesk/evo-auth:latest \
  ./evo-auth-service-community
ok "evo-auth pronto"

info "[2/6] evo-crm..."
docker build \
  -f ./evo-ai-crm-community/docker/Dockerfile \
  --build-arg BUNDLE_WITHOUT="" \
  --build-arg RAILS_ENV=production \
  --build-arg RAILS_SERVE_STATIC_FILES=true \
  -t wizzdesk/evo-crm:latest \
  ./evo-ai-crm-community
ok "evo-crm pronto"

info "[3/6] evo-core..."
docker build \
  -t wizzdesk/evo-core:latest \
  ./evo-ai-core-service-community
ok "evo-core pronto"

info "[4/6] evo-processor..."
docker build \
  -t wizzdesk/evo-processor:latest \
  ./evo-ai-processor-community
ok "evo-processor pronto"

info "[5/6] evo-bot-runtime..."
docker build \
  -t wizzdesk/evo-bot-runtime:latest \
  ./evo-bot-runtime
ok "evo-bot-runtime pronto"

info "[6/6] evo-frontend (VITE vars baked in)..."
docker build \
  --build-arg VITE_API_URL="$VITE_API_URL" \
  --build-arg VITE_AUTH_API_URL="$VITE_AUTH_API_URL" \
  --build-arg VITE_WS_URL="$VITE_WS_URL" \
  --build-arg VITE_EVOAI_API_URL="$VITE_EVOAI_API_URL" \
  --build-arg VITE_AGENT_PROCESSOR_URL="$VITE_AGENT_PROCESSOR_URL" \
  --build-arg VITE_TINYMCE_API_KEY="$VITE_TINYMCE_API_KEY" \
  -t wizzdesk/evo-frontend:latest \
  ./evo-ai-frontend-community
ok "evo-frontend pronto"

echo ""
echo "Todas as imagens construídas. Próximos passos:"
echo ""
echo "  1. Edita os CHANGE_ME_* no docker-stack.yml"
echo "  2. docker stack deploy -c docker-stack.yml wizzdesk"
echo "  3. bash seed.sh   (apenas na primeira vez)"