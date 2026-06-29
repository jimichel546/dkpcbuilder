#!/usr/bin/env bash
set -euo pipefail

# Подключить SSL в Nginx после: certbot certonly --manual --preferred-challenges dns
# Запуск: ./deploy/install-ssl-nginx.sh && ./deploy/enable-ssl.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

load_domains

apply_ssl_nginx_config "$APP_DIR"

echo "SSL подключён для https://${DOMAINS[0]}"
echo "Запустите: ./deploy/enable-ssl.sh"
