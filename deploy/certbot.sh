#!/usr/bin/env bash
set -euo pipefail

# SSL-сертификат Let's Encrypt для всех доменов из deploy/domains.txt.
# Запуск: ./deploy/certbot.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

load_domains

echo "==> Certbot для доменов: ${DOMAINS[*]}"
# shellcheck disable=SC2046
sudo certbot --nginx $(build_certbot_args)

echo "SSL установлен. Запустите: ./deploy/enable-ssl.sh"
