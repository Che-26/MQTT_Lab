#!/bin/bash

set -e

DOMAIN=${MQTT_EXTERNAL_IP}
CERTS_DIR="/mosquitto/certs"

echo "Generating SSL certificates for MQTT..."

# Создаем директорию если нет
mkdir -p $CERTS_DIR

# Генерируем CA
if [ ! -f "$CERTS_DIR/ca.key" ]; then
    echo "Generating CA certificate..."
    openssl genrsa -out $CERTS_DIR/ca.key 2048
    openssl req -x509 -new -nodes \
        -key $CERTS_DIR/ca.key \
        -sha256 -days 3650 \
        -out $CERTS_DIR/ca.crt \
        -subj "/C=US/ST=State/L=City/O=MQTT/CN=MQTT CA"
fi

# Генерируем серверный сертификат
if [ ! -f "$CERTS_DIR/server.key" ]; then
    echo "Generating server certificate..."
    
    # Создаем конфиг для SAN
    cat > $CERTS_DIR/server.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = MQTT Server
CN = ${DOMAIN}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = ${DOMAIN}
DNS.1 = ${DOMAIN}
DNS.2 = mqtt.local
EOF
    
    openssl genrsa -out $CERTS_DIR/server.key 2048
    openssl req -new \
        -key $CERTS_DIR/server.key \
        -out $CERTS_DIR/server.csr \
        -config $CERTS_DIR/server.cnf
    
    openssl x509 -req \
        -in $CERTS_DIR/server.csr \
        -CA $CERTS_DIR/ca.crt \
        -CAkey $CERTS_DIR/ca.key \
        -CAcreateserial \
        -out $CERTS_DIR/server.crt \
        -days 3650 \
        -sha256 \
        -extensions v3_req \
        -extfile $CERTS_DIR/server.cnf
    
    echo "Server certificates generated for ${DOMAIN}"
fi

# Создаем клиентский сертификат для веб-сервера
if [ ! -f "$CERTS_DIR/client.key" ]; then
    echo "Generating client certificate for web server..."
    
    openssl genrsa -out $CERTS_DIR/client.key 2048
    openssl req -new \
        -key $CERTS_DIR/client.key \
        -out $CERTS_DIR/client.csr \
        -subj "/C=US/ST=State/L=City/O=Web Server/CN=webserver"
    
    openssl x509 -req \
        -in $CERTS_DIR/client.csr \
        -CA $CERTS_DIR/ca.crt \
        -CAkey $CERTS_DIR/ca.key \
        -CAcreateserial \
        -out $CERTS_DIR/client.crt \
        -days 3650 \
        -sha256
    
    # Создаем PEM файл для клиента
    cat $CERTS_DIR/client.crt $CERTS_DIR/client.key > $CERTS_DIR/client.pem
    
    echo "Client certificates generated"
fi

chmod 644 $CERTS_DIR/*

echo "Certificate generation complete!"
echo "CA certificate: $CERTS_DIR/ca.crt"
echo "Server certificate: $CERTS_DIR/server.crt"
echo "Client certificate: $CERTS_DIR/client.pem"