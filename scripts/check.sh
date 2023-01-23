VAULT_BINARY=/usr/local/bin/vault
if [[ -f "$VAULT_BINARY" ]]; then
    echo "The Vault binary was found in the /usr/local/bin directory."
    echo "The Vault version installed is $(vault -v | awk '{ print $2 }')"
else
    echo "The Vault binary is missing from the /usr/local/bin directory."
fi

# Check for environment variables
if [[ -z "${VAULT_ADDR}" ]]; then
    echo "VAULT_ADDR is undefined and must be set to the FQDN of the internal load balancer of the Vault cluster."
else
    echo "VAULT_ADDR is properly set to ${VAULT_ADDR}"
fi

if [[ -z "${VAULT_CACERT}" ]]; then
    echo "VAULT_CACERT is undefined and must be set to the file location of the CA (Certificate Authority) bundle."
else
    echo "VAULT_CACERT is properly set to ${VAULT_CACERT}"
fi

# Check for TLS files
if [[ -f /opt/vault/tls/vault-cert.pem && -f /opt/vault/tls/vault-ca.pem && -f /opt/vault/tls/vault-key.pem ]]; then
    echo "All TLS files (CA bundle, Certificate, and Private Key) are properly located in the /opt/vault/tls directory."
else
    echo "Not all TLS files were found in the /opt/vault/tls directory."
fi

# Check for SSH Private Key
if [[ -f ~/.ssh/id_rsa ]]; then
    echo "The AWS SSH private key is stored in the proper location: ~/.ssh/id_rsa"
else
    echo "The AWS SSH private key is missing from the ~/.ssh/ directory."
fi