#!/bin/bash

set -e

cd ~/mqtt-vault-server

case "$1" in
    start)
        echo "Запуск MQTT + Vault сервера..."
        docker-compose up -d
        sleep 5
        
        echo "Генерация SSL сертификатов..."
        docker-compose exec mosquitto sh -c "
            mkdir -p /mosquitto/certs && \
            cd /mosquitto/certs && \
            openssl genrsa -out ca.key 2048 && \
            openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj '/C=RU/ST=Moscow/L=Moscow/O=MQTT/CN=MQTT CA' && \
            openssl genrsa -out server.key 2048 && \
            openssl req -new -key server.key -out server.csr -subj '/C=RU/ST=Moscow/L=Moscow/O=MQTT/CN=${EXTERNAL_IP}' && \
            openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 3650 -sha256 && \
            chmod 644 *.crt *.key
        "
        
        echo "Настройка Vault..."
        docker-compose exec vault /vault/scripts/setup-vault.sh
        
        echo "Сервер запущен успешно!"
        ;;
    
    stop)
        echo "Остановка сервера..."
        docker-compose down
        ;;
    
    restart)
        echo "Перезапуск сервера..."
        docker-compose restart
        ;;
    
    status)
        echo "Статус сервисов:"
        docker-compose ps
        echo ""
        echo "Логи MQTT:"
        docker-compose logs mosquitto --tail=20
        ;;
    
    logs)
        docker-compose logs -f ${2:-}
        ;;
    
    *)
        echo "Использование: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac