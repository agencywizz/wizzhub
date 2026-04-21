#!/usr/bin/env bash
# =============================================================================
# WizzDesk — Seed inicial (apenas na primeira vez)
# Corre depois de: docker stack deploy -c docker-stack.yml wizzdesk
# =============================================================================
set -e

echo "A aguardar que os serviços fiquem saudáveis..."
sleep 30

echo "[1/2] Seed auth service..."
docker exec \
  $(docker ps -q -f name=wizzdesk_evo-auth) \
  bundle exec rails db:seed

echo "[2/2] Seed CRM service..."
docker exec \
  $(docker ps -q -f name=wizzdesk_evo-crm) \
  bundle exec rails db:seed

echo ""
echo "Seed concluído. Acede a https://desk.wizzcomms.com"