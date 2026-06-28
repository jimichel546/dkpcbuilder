#!/usr/bin/env bash
set -euo pipefail

# Первичная установка на Ubuntu/Debian VPS.
# Запуск из корня проекта после git clone:
#   chmod +x deploy/*.sh
#   ./deploy/install.sh yourdomain.com

DOMAIN="${1:-}"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEPLOY_USER="$(whoami)"
SERVICE_NAME="pcstore"
NGINX_SITE="pcstore"

if [[ -z "$DOMAIN" ]]; then
    echo "Использование: ./deploy/install.sh yourdomain.com"
    exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
    echo "Не запускайте install.sh от root. Используйте обычного пользователя с sudo."
    exit 1
fi

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

domain = "${DOMAIN}"
env_path = Path(".env")
lines = env_path.read_text(encoding="utf-8").splitlines()
updates = {
    "SECRET_KEY": get_random_secret_key(),
    "DEBUG": "False",
    "ALLOWED_HOSTS": f"{domain},www.{domain}",
    "CSRF_TRUSTED_ORIGINS": f"https://{domain},https://www.{domain}",
    "SECURE_SSL_REDIRECT": "True",
}
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

mkdir -p media staticfiles

echo "==> Django: migrate и collectstatic"
python manage.py migrate --noinput
python manage.py collectstatic --noinput

echo "==> Systemd-сервис"
sed -e "s|__APP_DIR__|${APP_DIR}|g" -e "s|__DEPLOY_USER__|${DEPLOY_USER}|g" \
    deploy/pcstore.service | sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

echo "==> Nginx"
sed -e "s|__DOMAIN__|${DOMAIN}|g" -e "s|__APP_DIR__|${APP_DIR}|g" \
    deploy/nginx.conf | sudo tee "/etc/nginx/sites-available/${NGINX_SITE}" > /dev/null

sudo ln -sf "/etc/nginx/sites-available/${NGINX_SITE}" "/etc/nginx/sites-enabled/${NGINX_SITE}"
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo "Готово. Сайт доступен по HTTP: http://${DOMAIN}"
echo ""
echo "Следующие шаги:"
echo "  1. Убедитесь, что DNS A-запись домена указывает на IP этого сервера."
echo "  2. Создайте администратора: cd ${APP_DIR} && source venv/bin/activate && python manage.py createsuperuser"
echo "  3. Получите SSL: sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
echo "  4. После обновлений кода: ./deploy/update.sh"
