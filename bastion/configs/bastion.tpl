#!/usr/bin/env bash

#Utils
sleep 30
echo "Installing Updates"
touch /tmp/imhere.txt
sudo apt update
sudo apt install unzip
sudo apt install -y awscli
sudo apt install -y jq

#Vault
echo "Installing Vault"
cd /tmp && curl -O https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip
sudo unzip -o /tmp/vault* -d /usr/bin
sudo chown root:root /usr/bin/vault
#sudo useradd --system --home /etc/vault.d --shell /bin/false vault

#TLS
sudo mkdir -p /opt/vault/tls

secret_result=$(aws secretsmanager get-secret-value --secret-id ${secrets_manager_arn} --region ${aws_region} --output text --query SecretString)

jq -r .vault_cert <<< "$secret_result" | base64 -d > /opt/vault/tls/vault-cert.pem

jq -r .vault_ca <<< "$secret_result" | base64 -d > /opt/vault/tls/vault-ca.pem

jq -r .vault_pk <<< "$secret_result" | base64 -d > /opt/vault/tls/vault-key.pem

# SSH Key
cat << EOF | sudo tee -a /home/ubuntu/.ssh/id_rsa
${private_key_name}
EOF
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
sudo chmod 0600 /home/ubuntu/.ssh/id_rsa

# Profile
echo "Setup Vault profile"
cat << PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="https://${vault_lb_dns_name}:8200"
export VAULT_CACERT="/opt/vault/tls/vault-ca.pem"
PROFILE