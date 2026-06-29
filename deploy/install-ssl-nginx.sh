#!/usr/bin/env bash
set -euo pipefail

# Подключить SSL в Nginx после: certbot certonly --manual --preferred-challenges dns
# Запуск: ./deploy/install-ssl-nginx.sh && ./deploy/enable-ssl.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

load_domains
PRIMARY="${DOMAINS[0]}"
CERT_DIR="/etc/letsencrypt/live/${PRIMARY}"

if [[ ! -f "${CERT_DIR}/fullchain.pem" ]]; then
    echo "Ошибка: сертификат не найден: ${CERT_DIR}/fullchain.pem"
    echo "Сначала получите сертификат через DNS:"
    echo "  sudo certbot certonly --manual --preferred-challenges dns \\"
    echo "    -d ${PRIMARY} -d www.${PRIMARY} --agree-tos -m ваш@email.com"
    exit 1
fi

if [[ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]]; then
    sudo certbot install --cert-name "${PRIMARY}" --nginx 2>/dev/null || true
fi
if [[ ! -f /etc/letsencrypt/ssl-dhparams.pem ]]; then
    sudo openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
fi

server_names="$(build_server_names)"
sudo rm -f /etc/nginx/sites-enabled/*-le-ssl.conf
sed -e "s|__SERVER_NAMES__|${server_names}|g" \
    -e "s|__PRIMARY__|${PRIMARY}|g" \
    -e "s|__APP_DIR__|${APP_DIR}|g" \
    "${APP_DIR}/deploy/nginx-ssl.conf" | sudo tee /etc/nginx/sites-available/pcstore > /dev/null
sudo ln -sf /etc/nginx/sites-available/pcstore /etc/nginx/sites-enabled/pcstore
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo "SSL подключён для https://${PRIMARY}"
echo "Запустите: ./deploy/enable-ssl.sh"
