vault write -format=json pki_int/intermediate/generate/internal \
    common_name="IoT Intermediate CA" | jq -r '.data.csr' > pki_intermediate.csr

vault write -format=json pki_int/root/sign-intermediate \
    csr=@pki_intermediate.csr \
    common_name="IoT Intermediate CA" | jq -r '.data.certificate' > pki_intermediate.crt

vault write pki_int/intermediate/set-signed certificate=@pki_intermediate.crt
