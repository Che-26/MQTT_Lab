path "pki_int/issue/esp32-device" {
  capabilities = ["create", "update"]
  allowed_parameters = {
    common_name = ["*.esp32.iot.local"]
  }
}

path "pki_int/ca" {
  capabilities = ["read"]
}
