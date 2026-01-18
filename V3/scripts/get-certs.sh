#!/bin/bash

DOMAIN_MQTT="mqtt.yourdomain.com"
DOMAIN_VAULT="vault.yourdomain.com"
EMAIL="admin@yourdomain.com"
CERT_DIR="./mosquitto/certs"
VAULT_CERT_DIR="./vault/tls"

sudo certbot certonly --standalone -d $DOMAIN_MQTT -d $DOMAIN_VAULT --email $EMAIL --agree-tos -n --preferred-challenges http

sudo cp /etc/letsencrypt/live/$DOMAIN_MQTT/fullchain.pem $CERT_DIR/
sudo cp /etc/letsencrypt/live/$DOMAIN_MQTT/privkey.pem $CERT_DIR/
sudo cp /etc/letsencrypt/live/$DOMAIN_MQTT/chain.pem $CERT_DIR/

sudo cp /etc/letsencrypt/live/$DOMAIN_VAULT/fullchain.pem $VAULT_CERT_DIR/vault.crt
sudo cp /etc/letsencrypt/live/$DOMAIN_VAULT/privkey.pem $VAULT_CERT_DIR/vault.key

sudo chown -R $USER:$USER $CERT_DIR
sudo chown -R $USER:$USER $VAULT_CERT_DIR
sudo chmod 600 $CERT_DIR/privkey.pem $VAULT_CERT_DIR/vault.key

echo "✅ Сертификаты получены"
