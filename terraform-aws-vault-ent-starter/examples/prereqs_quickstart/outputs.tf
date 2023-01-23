/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

output "lb_certificate_arn" {
  description = "ARN of ACM cert to use with Vault LB listener"
  value       = module.secrets.lb_certificate_arn
}

output "leader_tls_servername" {
  description = "Shared SAN that will be given to the Vault nodes configuration for use as leader_tls_servername"
  value       = module.secrets.leader_tls_servername
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

### MANUALLY ADDED -nyoung
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "resource_name_prefix" {
  description = "Resource name prefix"
  value       = var.resource_name_prefix
}
### END OF ADDITIONS -nyoung


output "secrets_manager_arn" {
  description = "ARN of secrets_manager secret"
  value       = module.secrets.secrets_manager_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_tags" {
  description = "tags of public subnets that will be used to filter them for Bastion hosts"
  value = module.vpc.public_subnet_tags
}
