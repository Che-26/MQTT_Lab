#!/bin/bash
export VAULT_ADDR=https://vault.yourdomain.com:2291
export VAULT_TOKEN=root

vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=87600h pki_int

vault write -field=certificate pki_int/root/generate/internal \
    common_name="IoT Internal CA" \
    ttl=87600h > ca_cert.crt

vault write pki_int/config/urls \
    issuing_certificates="$VAULT_ADDR/v1/pki_int/ca" \
    crl_distribution_points="$VAULT_ADDR/v1/pki_int/crl"
