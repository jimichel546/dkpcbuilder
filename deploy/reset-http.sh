#!/usr/bin/env bash
set -euo pipefail

# Сброс на чистый HTTP перед certbot (убирает редиректы certbot в Nginx).
# Запуск: ./deploy/reset-http.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="pcstore"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

load_domains
load_server_ip

cd "$APP_DIR"
source venv/bin/activate

echo "==> SECURE_SSL_REDIRECT=False"
update_env_domains "$APP_DIR" "false"
sudo systemctl restart "${SERVICE_NAME}"

echo "==> Удаление SSL-конфигов certbot из Nginx"
sudo rm -f /etc/nginx/sites-enabled/*-le-ssl.conf
sudo rm -f /etc/nginx/sites-available/*-le-ssl.conf

echo "==> Чистый HTTP-конфиг Nginx"
apply_nginx_config "$APP_DIR"

echo ""
echo "Проверка:"
curl -I http://127.0.0.1 -H "Host: ${DOMAINS[0]}" | head -n 1
echo ""
echo "Должно быть: HTTP/1.1 200 OK"
echo ""
echo "SSL через DNS (если certbot --nginx даёт timeout):"
echo "  sudo certbot certonly --manual --preferred-challenges dns \\"
echo "    -d ${DOMAINS[0]} -d www.${DOMAINS[0]} --agree-tos -m ваш@email.com"
echo "  ./deploy/install-ssl-nginx.sh && ./deploy/enable-ssl.sh"
