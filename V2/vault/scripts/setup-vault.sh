#!/bin/bash

echo "======================================="
echo "   Настройка Vault для MQTT системы    "
echo "======================================="

# Ждем запуска Vault
echo "Ожидание запуска Vault..."
sleep 15

# Проверяем доступность
for i in {1..30}; do
    if curl -s http://127.0.0.1:8200/v1/sys/health > /dev/null; then
        echo "✓ Vault запущен"
        break
    fi
    echo "Ожидание Vault... ($i/30)"
    sleep 2
done

# Экспортируем переменные
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root-token-${VAULT_SECRET}'

echo ""
echo "1. Включаем KV секреты..."
vault secrets enable -path=mqtt kv-v2

echo ""
echo "2. Создаем политики..."

# Политика для ESP32
vault policy write esp32-policy - <<EOF
path "mqtt/data/esp32/*" {
  capabilities = ["read"]
}
EOF

# Политика для веб-сервера
vault policy write webserver-policy - <<EOF
path "mqtt/data/webserver/*" {
  capabilities = ["read"]
}
EOF

echo ""
echo "3. Генерируем пароли..."

# Генерация паролей
ESP32_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)
WEB_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)
DEBUG_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-16)

echo ""
echo "4. Сохраняем секреты в Vault..."

# ESP32
vault kv put mqtt/esp32/credentials \
  username="esp32" \
  password="$ESP32_PASSWORD" \
  server="${EXTERNAL_IP}" \
  port="2292" \
  use_tls="true"

# Веб-сервер
vault kv put mqtt/webserver/credentials \
  username="webserver" \
  password="$WEB_PASSWORD" \
  server="${EXTERNAL_IP}" \
  port="2292" \
  port_ws="9001"

# Отладка
vault kv put mqtt/debug/credentials \
  username="debug" \
  password="$DEBUG_PASSWORD"

echo ""
echo "5. Настраиваем аутентификацию AppRole..."
vault auth enable approle

# ESP32 AppRole
vault write auth/approle/role/esp32 \
  secret_id_ttl=8760h \
  token_ttl=1h \
  token_max_ttl=24h \
  policies="esp32-policy"

# Веб-сервер AppRole
vault write auth/approle/role/webserver \
  secret_id_ttl=8760h \
  token_ttl=24h \
  token_max_ttl=168h \
  policies="webserver-policy"

echo ""
echo "6. Получаем Role IDs..."
ESP32_ROLE_ID=$(vault read -field=role_id auth/approle/role/esp32/role-id)
WEBSERVER_ROLE_ID=$(vault read -field=role_id auth/approle/role/webserver/role-id)

echo ""
echo "7. Генерируем Secret IDs..."
ESP32_SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/esp32/secret-id)
WEBSERVER_SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/webserver/secret-id)

echo ""
echo "8. Создаем файл паролей для Mosquitto..."
cat > /vault/scripts/passwd.tmp <<EOF
webserver:$WEB_PASSWORD
debug:$DEBUG_PASSWORD
EOF

# Копируем файл паролей
cp /vault/scripts/passwd.tmp /mosquitto/config/passwd

echo ""
echo "======================================="
echo "     НАСТРОЙКА ЗАВЕРШЕНА УСПЕШНО!     "
echo "======================================="
echo ""
echo "ИНФОРМАЦИЯ ДЛЯ ПОДКЛЮЧЕНИЯ:"
echo ""
echo "--- Vault ---"
echo "URL: http://${EXTERNAL_IP}:2290"
echo "Token: root-token-${VAULT_SECRET}"
echo ""
echo "--- MQTT ---"
echo "Адрес: ${EXTERNAL_IP}"
echo "Порт без TLS: 2291"
echo "Порт с TLS: 2292"
echo "WebSocket: ${EXTERNAL_IP}:9001 (только внутри сети)"
echo ""
echo "--- Учетные данные MQTT ---"
echo "Веб-сервер:"
echo "  Логин: webserver"
echo "  Пароль: $WEB_PASSWORD"
echo ""
echo "Отладка:"
echo "  Логин: debug"
echo "  Пароль: $DEBUG_PASSWORD"
echo ""
echo "--- AppRole IDs ---"
echo "ESP32 Role ID: $ESP32_ROLE_ID"
echo "ESP32 Secret ID: $ESP32_SECRET_ID"
echo "WebServer Role ID: $WEBSERVER_ROLE_ID"
echo "WebServer Secret ID: $WEBSERVER_SECRET_ID"
echo ""
echo "======================================="
echo "СОХРАНИТЕ ЭТУ ИНФОРМАЦИЮ В БЕЗОПАСНОЕ МЕСТО!"
echo "======================================="