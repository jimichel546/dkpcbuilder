#!/usr/bin/env bash
# Общие функции для deploy-скриптов.

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMAINS_FILE="${DEPLOY_DIR}/domains.txt"
SERVER_IP_FILE="${DEPLOY_DIR}/server-ip.txt"

load_domains() {
    DOMAINS=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] && DOMAINS+=("$line")
    done < "$DOMAINS_FILE"

    if [[ ${#DOMAINS[@]} -eq 0 ]]; then
        echo "Ошибка: deploy/domains.txt пуст или не найден." >&2
        exit 1
    fi
}

load_server_ip() {
    SERVER_IP=""
    if [[ -f "$SERVER_IP_FILE" ]]; then
        SERVER_IP="$(grep -v '^#' "$SERVER_IP_FILE" | grep -v '^[[:space:]]*$' | head -n1 | tr -d '[:space:]')"
    fi
}

build_server_names() {
    local names=()
    for domain in "${DOMAINS[@]}"; do
        names+=("$domain" "www.${domain}")
    done
    echo "${names[*]}"
}

build_allowed_hosts() {
    local hosts=()
    for domain in "${DOMAINS[@]}"; do
        hosts+=("$domain" "www.${domain}")
    done
    if [[ -n "$SERVER_IP" ]]; then
        hosts+=("$SERVER_IP")
    fi
    local IFS=,
    echo "${hosts[*]}"
}

build_csrf_origins() {
    local scheme="${1:-http}"
    local origins=()
    for domain in "${DOMAINS[@]}"; do
        origins+=("${scheme}://${domain}" "${scheme}://www.${domain}")
    done
    local IFS=,
    echo "${origins[*]}"
}

build_csrf_origins_mixed() {
    local origins=()
    for domain in "${DOMAINS[@]}"; do
        origins+=("http://${domain}" "http://www.${domain}" "https://${domain}" "https://www.${domain}")
    done
    local IFS=,
    echo "${origins[*]}"
}

build_certbot_args() {
    local args=()
    for domain in "${DOMAINS[@]}"; do
        args+=("-d" "$domain" "-d" "www.${domain}")
    done
    echo "${args[@]}"
}

apply_nginx_config() {
    local app_dir="$1"
    local server_names
    server_names="$(build_server_names)"
    sed -e "s|__SERVER_NAMES__|${server_names}|g" -e "s|__APP_DIR__|${app_dir}|g" \
        "${DEPLOY_DIR}/nginx.conf" | sudo tee "/etc/nginx/sites-available/pcstore" > /dev/null
    sudo ln -sf "/etc/nginx/sites-available/pcstore" "/etc/nginx/sites-enabled/pcstore"
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t
    sudo systemctl reload nginx
}

update_env_domains() {
    local app_dir="$1"
    local secure_ssl_redirect="${2:-keep}"
    local allowed_hosts csrf_origins

    allowed_hosts="$(build_allowed_hosts)"
    if [[ "$secure_ssl_redirect" == "true" ]]; then
        csrf_origins="$(build_csrf_origins https)"
    elif [[ "$secure_ssl_redirect" == "false" ]]; then
        csrf_origins="$(build_csrf_origins_mixed)"
    else
        csrf_origins=""
    fi

    ALLOWED_HOSTS_VAL="$allowed_hosts" \
    CSRF_ORIGINS_VAL="$csrf_origins" \
    SECURE_SSL_REDIRECT_VAL="$secure_ssl_redirect" \
    APP_DIR_VAL="$app_dir" \
    python - <<'PY'
import os
from pathlib import Path

env_path = Path(os.environ["APP_DIR_VAL"]) / ".env"
lines = env_path.read_text(encoding="utf-8").splitlines() if env_path.exists() else []

updates = {"ALLOWED_HOSTS": os.environ["ALLOWED_HOSTS_VAL"]}
csrf = os.environ.get("CSRF_ORIGINS_VAL", "")
if csrf:
    updates["CSRF_TRUSTED_ORIGINS"] = csrf
ssl_mode = os.environ.get("SECURE_SSL_REDIRECT_VAL", "keep")
if ssl_mode in ("true", "false"):
    updates["SECURE_SSL_REDIRECT"] = "True" if ssl_mode == "true" else "False"

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
}
