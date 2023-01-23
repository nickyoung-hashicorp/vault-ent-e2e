# Shutdown EC2 instances with tags Name=nyoung*

aws ec2 stop-instances --instance-ids $(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --filters "Name=tag:Name,Values=nyoung*" --output text)

# Start EC2 instances with tags Name=nyoung*

aws ec2 start-instances --instance-ids $(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --filters "Name=tag:Name,Values=nyoung*" --output text)'



export RESOURCE_PREFIX=nyoung
export REGION=us-east-1

aws ec2 describe-instances --query 'Reservations[].Instances[].PrivateIpAddress' --filters "Name=tag:Name,Values=${RESOURCE_PREFIX}-vault-server" --region ${REGION} --output json

aws ec2 describe-instances --query 'Reservations[].Instances[].PrivateIpAddress[]' --filters "Name=tag:Name,Values=${RESOURCE_PREFIX}-vault-server" --region ${REGION} --output json | jq '.[]' | tr '\n' ', '

aws ec2 describe-instances --query 'Reservations[].Instances[].PrivateIpAddress[]' --filters "Name=tag:Name,Values=nyoung-vault-server" --region us-east-1 --output json | jq '.[]' | tr '\n' ', '