#!/usr/bin/env bash
set -euo pipefail

# Включить HTTPS-редирект после успешного certbot.
# Запуск из корня проекта: ./deploy/enable-ssl.sh yourdomain.com

DOMAIN="${1:-}"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="pcstore"

if [[ -z "$DOMAIN" ]]; then
    echo "Использование: ./deploy/enable-ssl.sh yourdomain.com"
    exit 1
fi

cd "$APP_DIR"
source venv/bin/activate

python - <<PY
from pathlib import Path

domain = "${DOMAIN}"
env_path = Path(".env")
lines = env_path.read_text(encoding="utf-8").splitlines()
updates = {
    "SECURE_SSL_REDIRECT": "True",
    "CSRF_TRUSTED_ORIGINS": f"https://{domain},https://www.{domain}",
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

sudo systemctl restart "${SERVICE_NAME}"
echo "HTTPS включён: SECURE_SSL_REDIRECT=True, сервис перезапущен."
