# Walkthrough

## Prerequisites:
 - Terraform v.1.2.7
 - aws-cli/2.5.1
 - Vault Enterprise (latest)


## Provision Infrastructure
Clone the repo and provisiong the AWS infrastructure
```
git clone <REPO>
cd <REPO>
terraform init && terraform apply -auto-approve -parallelism=50
```

## Setup Vault Enterprise with Integrated Storage
Once the apply completes, save the variables as follows:
```
REGION=us-east-1
PREFIX=$(terraform output -raw resource_name_prefix)
TARGET_GROUP=$(terraform output -raw vault_target_group_arn)
```

Open a browser and log into your AWS console using your account credentials.  Once authenticated, return to your terminal and run the following command:
```
echo "View the Vault target group - https://${REGION}.console.aws.amazon.com/ec2/v2/home?region=${REGION}#TargetGroup:targetGroupArn=${TARGET_GROUP}"
```
Click the URL which should take you straight into a view of your Vault cluster and its instances as a Target Group.  All nodes should appear `Unhealthy` beause Vault has not been initialized on any of the nodes.

With the `awscli`, save the first Vault instance ID as a variable.  The exact one does not matter since it will become the first active Vault node after it is initialized.
```
INSTANCE_ID_1=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${PREFIX}-vault-server" --query "Reservations[*].Instances[*].InstanceId[]" --output json --region ${REGION} | jq -r '.[0]')

echo "Open AWS Systems Manager in a web browser - https://${REGION}.console.aws.amazon.com/systems-manager/session-manager/${INSTANCE_ID_1}?region=${REGION}#"
```
This should place you straight into a session via Systems Manager to the first Vault node through your web browser.  Elevate permissions, check for the Vault binary version to confirm the desired version number and the `+ent` binary.
```
sudo -i
vault -v
```

NOTE: If Vault did not install properly, check the cloud-init logs for errors:
```
cat /var/log/cloud-init-output.log
```

Initializes this Vault node, save the file holding the unseal key(s) and root token, and save the Vault variables
```
vault operator init -address='https://localhost:8200' -recovery-shares=1 -recovery-threshold=1 -format=json > init.json

cat init.json

export VAULT_ADDR=https://localhost:8200
export VAULT_TOKEN=$(cat init.json | jq -r '.root_token')
```

Check for this active, single node in the cluster
```
vault operator raft list-peers
```

Leave your browser and return to your original terminal.
Save the remaining 4 inactive Vault nodes and their instance IDs
```
INSTANCE_ID_2=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${PREFIX}-vault-server" --query "Reservations[*].Instances[*].InstanceId[]" --output json --region ${REGION} | jq -r '.[1]')

INSTANCE_ID_3=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${PREFIX}-vault-server" --query "Reservations[*].Instances[*].InstanceId[]" --output json --region ${REGION} | jq -r '.[2]')

INSTANCE_ID_4=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${PREFIX}-vault-server" --query "Reservations[*].Instances[*].InstanceId[]" --output json --region ${REGION} | jq -r '.[3]')

INSTANCE_ID_5=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=${PREFIX}-vault-server" --query "Reservations[*].Instances[*].InstanceId[]" --output json --region ${REGION} | jq -r '.[4]')
```

This command will restart the Vault service on the 4 remaining, inactive Vault nodes.  Once the service is restart, the tags configured using the auto_join feature will find and join the active Vault node to complete the cluster.
```
aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo systemctl restart vault"]' \
    --targets Key=instanceids,Values=${INSTANCE_ID_2},${INSTANCE_ID_3},${INSTANCE_ID_4},${INSTANCE_ID_5}
```
Press `q` to quit the output.

Return to your web browser's Systems Manager session with the first active Vault node.
Validate there is now 1 node in the `leader` state along with 4 nodes in the `follower` state.
```
vault operator raft list-peers
```

Finally, check that the Vault Enterprise license was properly loaded, licenses are valid where the expiration and termination dates are in the future, and the license key has the `Performance Standby` feature enabled.
```
vault read /sys/license/status -format=json | jq '.data.autoloaded.features' | grep 'Performance Standby'
vault read /sys/license/status -format=json | jq '.data.autoloaded.expiration_time'
vault read /sys/license/status -format=json | jq '.data.autoloaded.termination_time'
```

## Setup Grafana
SSH to the EC2 instance running Grafana
```
ssh -i awskey.pem ubuntu@$(terraform output -json telemetry_public_ip | jq -r '.[0]')
```

Check for the Vault binary, the TLS files (CA bundle, certificate, and key), SSH private key, and environment variables
```
echo "Checking for the Vault binary"
VAULT_BINARY=/usr/local/bin/vault
if [[ -f "$VAULT_BINARY" ]]; then
    echo "The Vault binary was found in the /usr/local/bin directory."
    echo "The Vault version installed is $(vault -v | awk '{ print $2 }')"
else
    echo "The Vault binary is missing from the /usr/local/bin directory."
fi

echo "Checking for the proper environment variables"
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

echo "Checking for TLS files"
if [[ -f /opt/vault/tls/vault-cert.pem && -f /opt/vault/tls/vault-ca.pem && -f /opt/vault/tls/vault-key.pem ]]; then
    echo "All TLS files (CA bundle, Certificate, and Private Key) are properly located in the /opt/vault/tls directory."
else
    echo "Not all TLS files were found in the /opt/vault/tls directory."
fi

echo "Checking for the SSH Private Key"
if [[ -f ~/.ssh/id_rsa ]]; then
    echo "The AWS SSH private key is stored in the proper location: ~/.ssh/id_rsa"
else
    echo "The AWS SSH private key is missing from the ~/.ssh/ directory."
fi
```
This indicates that the template files were processed properly as part of the user data script for the bastion / worker node(s).

# TO-DO: FINISH INSTRUCTIONS FOR GRAFANA SETUP

## Setup Benchmark / Bastion Nodes
SSH to an EC2 instance intended for running the `benchmark-vault` tool
```
ssh -i awskey.pem ubuntu@$(terraform output -json benchmark_public_ip | jq -r '.[0]')
```

Check for the Vault binary, the TLS files (CA bundle, certificate, and key), SSH private key, and environment variables
```
echo "Checking for the Vault binary"
VAULT_BINARY=/usr/local/bin/vault
if [[ -f "$VAULT_BINARY" ]]; then
    echo "The Vault binary was found in the /usr/local/bin directory."
    echo "The Vault version installed is $(vault -v | awk '{ print $2 }')"
else
    echo "The Vault binary is missing from the /usr/local/bin directory."
fi

echo "Checking for the proper environment variables"
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

echo "Checking for TLS files"
if [[ -f /opt/vault/tls/vault-cert.pem && -f /opt/vault/tls/vault-ca.pem && -f /opt/vault/tls/vault-key.pem ]]; then
    echo "All TLS files (CA bundle, Certificate, and Private Key) are properly located in the /opt/vault/tls directory."
else
    echo "Not all TLS files were found in the /opt/vault/tls directory."
fi

echo "Checking for the SSH Private Key"
if [[ -f ~/.ssh/id_rsa ]]; then
    echo "The AWS SSH private key is stored in the proper location: ~/.ssh/id_rsa"
else
    echo "The AWS SSH private key is missing from the ~/.ssh/ directory."
fi
```
This indicates that the template files were processed properly as part of the user data script for the telemetry / Grafana node.


# TO-DO: FINISH INSTRUCTIONS FOR BENCHMARK NODE(S) SETUP

## Clean Up
```
terraform destroy -auto-approve
```