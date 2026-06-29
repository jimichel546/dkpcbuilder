#!/usr/bin/env bash
set -euo pipefail

# Первичная установка на Ubuntu/Debian VPS.
# Домены задаются в deploy/domains.txt
# Запуск: chmod +x deploy/*.sh && ./deploy/install.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_USER="$(whoami)"
SERVICE_NAME="pcstore"

# shellcheck source=common.sh
source "${APP_DIR}/deploy/common.sh"

if [[ "$EUID" -eq 0 ]]; then
    echo "Не запускайте install.sh от root. Используйте обычного пользователя с sudo."
    exit 1
fi

load_domains
load_server_ip
PRIMARY_DOMAIN="${DOMAINS[0]}"

echo "==> Домены: ${DOMAINS[*]}"

echo "==> Установка системных пакетов"
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx git certbot python3-certbot-nginx

echo "==> Python-окружение"
cd "$APP_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "==> Файл .env"
if [[ ! -f .env ]]; then
    cp .env.example .env
fi

python - <<PY
from pathlib import Path
from django.core.management.utils import get_random_secret_key

env_path = Path(".env")
lines = env_path.read_text(encoding="utf-8").splitlines() if env_path.exists() else []
updates = {"SECRET_KEY": get_random_secret_key()}
seen = set()
result = []
for line in lines:
    key = line.split("=", 1)[0].strip() if "=" in line and not line.strip().startswith("#") else None
    if key in updates:
        result.append(f"{key}={updates[key]}")
        seen.add(key)
    else:
        result.append(line)
for key, value in updates.items():
    if key not in seen:
        result.append(f"{key}={value}")
env_path.write_text("\n".join(result) + "\n", encoding="utf-8")
PY

update_env_domains "$APP_DIR" "false"

mkdir -p media staticfiles

echo "==> Django: migrate и collectstatic"
python manage.py migrate --noinput
python manage.py collectstatic --noinput

echo "==> Права доступа для Nginx (static/media)"
chmod o+x "$HOME"
chmod -R o+rX "${APP_DIR}/staticfiles" "${APP_DIR}/media"

echo "==> Systemd-сервис"
sed -e "s|__APP_DIR__|${APP_DIR}|g" -e "s|__DEPLOY_USER__|${DEPLOY_USER}|g" \
    deploy/pcstore.service | sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo "==> Nginx"
apply_nginx_config "$APP_DIR"

echo ""
echo "Готово. Основной домен: http://${PRIMARY_DOMAIN}"
echo ""
echo "Следующие шаги:"
echo "  1. Настройте DNS A-записи для всех доменов из deploy/domains.txt"
echo "  2. Создайте администратора: cd ${APP_DIR} && source venv/bin/activate && python manage.py createsuperuser"
echo "  3. Получите SSL: ./deploy/certbot.sh"
echo "  4. Включите HTTPS-редирект: ./deploy/enable-ssl.sh"
echo "  5. После обновлений кода: ./deploy/update.sh"
