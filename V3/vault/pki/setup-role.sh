vault write pki_int/roles/esp32-device \
    allowed_domains="esp32.iot.local" \
    allow_subdomains=false \
    max_ttl="720h" \
    ttl="240h" \
    key_usage="digitalSignature,keyEncipherment" \
    ext_key_usage="clientAuth" \
    generate_lease=true
