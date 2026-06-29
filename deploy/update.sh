#!/usr/bin/env bash
set -euo pipefail

# Обновление после git pull.
# Запуск: ./deploy/update.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="pcstore"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

load_domains
load_server_ip

cd "$APP_DIR"

echo "==> git pull"
git pull

echo "==> Зависимости"
source venv/bin/activate
pip install -r requirements.txt

echo "==> Django"
python manage.py migrate --noinput
python manage.py collectstatic --noinput
chmod o+x "$HOME"
chmod -R o+rX "${APP_DIR}/staticfiles" "${APP_DIR}/media"

echo "==> Домены и Nginx"
if [[ -f .env ]] && grep -q '^SECURE_SSL_REDIRECT=True' .env; then
    update_env_domains "$APP_DIR" "true"
else
    update_env_domains "$APP_DIR" "false"
fi
apply_nginx_config "$APP_DIR"

echo "==> Перезапуск сервиса"
sudo systemctl restart "${SERVICE_NAME}"

echo "Обновление завершено. Домены: ${DOMAINS[*]}"
