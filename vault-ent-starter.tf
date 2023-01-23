### Vault Enterprise Starter - Vault Enterprise with Integrated Storage
### Includes all created resources, variables, and outputs

module "vault-ent-starter" {
  source = "./terraform-aws-vault-ent-starter"

  # REQUIRED INPUTS
  lb_certificate_arn    = module.vault-prereqs.lb_certificate_arn    # REQUIRED
  leader_tls_servername = module.vault-prereqs.leader_tls_servername # REQUIRED
  private_subnet_ids    = module.vault-prereqs.private_subnet_ids    # REQUIRED
  resource_name_prefix  = "nyoung"                                   # REQUIRED
  secrets_manager_arn   = module.vault-prereqs.secrets_manager_arn   # REQUIRED
  vpc_id                = module.vault-prereqs.vpc_id                # REQUIRED

  # optional inputs
  allowed_inbound_cidrs_lb  = ["0.0.0.0/0"]                # optional
  allowed_inbound_cidrs_ssh = ["0.0.0.0/0"]                # optional
  instance_type             = "m5.xlarge"                  # default
  key_name                  = aws_key_pair.awskey.key_name # generated from ssh.tf
  lb_type                   = "network"                    # "application" is the other option and default
  node_count                = 5                            # default
  vault_version             = "1.11.2"                     # defaults to the latest Enterprise binary
  vault_license_filepath    = "./vault.hclic"              # references local file directory for a valid Vault Enterprise license
}

output "asg_name" {
  value = module.vault-ent-starter.asg_name
}

output "kms_key_arn" {
  value = module.vault-ent-starter.kms_key_arn
}

output "launch_template_id" {
  value = module.vault-ent-starter.launch_template_id
}

output "vault_lb_dns_name" {
  description = "DNS name of Vault internal load balancer"
  value       = module.vault-ent-starter.vault_lb_dns_name
}

output "vault_lb_zone_id" {
  description = "Zone ID of Vault load balancer"
  value       = module.vault-ent-starter.vault_lb_zone_id
}

output "vault_lb_arn" {
  description = "ARN of Vault load balancer"
  value       = module.vault-ent-starter.vault_lb_arn
}

output "vault_target_group_arn" {
  description = "Target group ARN to register Vault nodes with"
  value       = module.vault-ent-starter.vault_target_group_arn
}

output "vault_sg_id" {
  description = "Security group ID of Vault cluster"
  value       = module.vault-ent-starter.vault_sg_id
}
