#!/usr/bin/env bash
set -euo pipefail

# Включить HTTPS-редирект после успешного certbot.
# Запуск: ./deploy/enable-ssl.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="pcstore"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

load_domains
load_server_ip

cd "$APP_DIR"
source venv/bin/activate

update_env_domains "$APP_DIR" "true"

sudo systemctl restart "${SERVICE_NAME}"
echo "HTTPS включён для: ${DOMAINS[*]}"
