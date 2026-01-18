#!/bin/bash
cd /path/to/iot-secure

if certbot renew --quiet; then
  cp /etc/letsencrypt/live/mqtt.yourdomain.com/fullchain.pem ./mosquitto/certs/fullchain.pem
  cp /etc/letsencrypt/live/mqtt.yourdomain.com/privkey.pem ./mosquitto/certs/privkey.pem
  cp /etc/letsencrypt/live/vault.yourdomain.com/fullchain.pem ./vault/tls/vault.crt
  cp /etc/letsencrypt/live/vault.yourdomain.com/privkey.pem ./vault/tls/vault.key

  docker-compose restart mosquitto vault
  echo "$(date): Сертификаты обновлены и сервисы перезапущены" >> /var/log/cert-renew.log
fi
