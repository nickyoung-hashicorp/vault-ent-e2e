### Vault Prerequisites - VPC, Networking, TLS, Secrets
### Includes all created resources, variables, and outputs

module "vault-prereqs" {
  source               = "./terraform-aws-vault-ent-starter/examples/prereqs_quickstart"
  resource_name_prefix = "nyoung"
}

output "lb_certificate_arn" {
  description = "ARN of ACM cert to use with Vault LB listener"
  value       = module.vault-prereqs.lb_certificate_arn
}

output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = module.vault-prereqs.leader_tls_servername
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vault-prereqs.private_subnet_ids
}

### MANUALLY ADDED -nyoung
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vault-prereqs.public_subnet_ids
}

output "secrets_manager_arn" {
  description = "ARN of secrets_manager secret"
  value       = module.vault-prereqs.secrets_manager_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vault-prereqs.vpc_id
}

output "resource_name_prefix" {
  description = "Resourece name prefix"
  value       = module.vault-prereqs.resource_name_prefix
}

