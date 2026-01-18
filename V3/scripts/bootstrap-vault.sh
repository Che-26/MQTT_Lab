#!/bin/bash
export VAULT_ADDR=https://vault.yourdomain.com:2291
export VAULT_TOKEN=root

until curl -k -s $VAULT_ADDR/v1/sys/health | grep -q '"initialized":true'; do sleep 5; done

sh ./vault/pki/config-pki.sh
sh ./vault/pki/setup-intermediate.sh
sh ./vault/pki/setup-role.sh

echo "✅ Vault PKI настроен"
