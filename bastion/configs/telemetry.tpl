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

#Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install -y docker-ce
sudo usermod -aG docker $USER


#Prometheus
sleep 10 #~wait for aws cli to install

#REMOVED - doesn't really work as ASG instances are refreshed and populates with stale IPs
#aws_asg_instance_private_ips=$(for x in $(aws --output text --query "AutoScalingGroups[0].Instances[*].InstanceId" autoscaling describe-auto-scaling-groups --auto-scaling-group-names nyoung-vault --region us-east-1) ; do echo $(aws --region us-east-1 ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=$x" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text):8200,; done)

sudo mkdir -p /etc/prometheus

cat << EOF | sudo tee -a /etc/prometheus/prometheus.yml
scrape_configs:
  - job_name: 'grafana'
    metrics_path: '/v1/sys/metrics'
    params:
      format: [prometheus]
    #bearer_token: 'example'
    scheme: 'https'
    tls_config:
      insecure_skip_verify: true
      ca_file: /etc/prometheus/vault-ca.pem
      cert_file: /etc/prometheus/vault-cert.pem
      key_file: /etc/prometheus/vault-key.pem
    static_configs:
    #- targets: [ $aws_asg_instance_private_ips ]
    - targets: []
EOF

sudo docker network create --attachable --subnet 10.42.74.0/24 telemetry

sudo docker run \
  --detach \
  --name prometheus \
  --ip 10.42.74.110 \
  --network telemetry \
  -p 9090:9090 \
  -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v /opt/vault/tls:/etc/prometheus \
      prom/prometheus

#Grafana
sudo mkdir -p /etc/grafana

cat << EOF | sudo tee -a /etc/grafana/datasource.yml
# config file version
apiVersion: 1

datasources:
- name: grafana
  type: prometheus
  access: server
  orgId: 1
  url: http://10.42.74.110:9090
  password:
  user:
  database:
  basicAuth:
  basicAuthUser:
  basicAuthPassword:
  withCredentials:
  isDefault:
  jsonData:
     graphiteVersion: "1.1"
     tlsAuth: false
     tlsAuthWithCACert: false
  secureJsonData:
    tlsCACert: ""
    tlsClientCert: ""
    tlsClientKey: ""
  version: 1
  editable: true
EOF

docker run \
    --detach \
    --name grafana \
    --ip 10.42.74.120 \
    --network telemetry \
    -p 3000:3000 \
    -v /etc/grafana/datasource.yml:/etc/grafana/provisioning/datasources/prometheus_datasource.yml \
    grafana/grafana

#SSH
cat << EOF | sudo tee -a /home/ubuntu/.ssh/id_rsa
${private_key_name}
EOF
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
sudo chmod 0600 /home/ubuntu/.ssh/id_rsa

echo "Setup Vault profile"
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="https://${vault_lb_dns_name}:8200"
export VAULT_CACERT="/opt/vault/tls/vault-ca.pem"
PROFILE
