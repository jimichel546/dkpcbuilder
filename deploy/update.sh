#!/usr/bin/env bash
set -euo pipefail

# Обновление после git pull.
# Запуск из корня проекта: ./deploy/update.sh

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="pcstore"

cd "$APP_DIR"

echo "==> git pull"
git pull

echo "==> Зависимости"
source venv/bin/activate
pip install -r requirements.txt

echo "==> Django"
python manage.py migrate --noinput
python manage.py collectstatic --noinput

echo "==> Перезапуск сервиса"
sudo systemctl restart "${SERVICE_NAME}"

echo "Обновление завершено."
