variable "resource_name_prefix" {}
variable "vpc_id" {}
variable "aws_region" {}

variable "vault_lb_sg_id" {
  description = "Security Group for Bastion to reach LB for benchmarking"
}

variable "aws_iam_instance_profile" {
  description = "same IAM profile as Vault nodes for bastion/telemetry nodes to fetch tls from ASM"
}
variable "vault_lb_dns_name" {
  description = "for telemetry node to reach vault cluster & VAULT_ADDR export"
}
variable "secrets_manager_arn" {
  description = "tls certs stored in ASM"
}
variable "bastion_count" {
  default = 3
}

variable "telemetry_count" {
  default = 1
}

variable "instance_type" {
  default = "t2.medium"
}

variable "vault_version" {
  default = "1.10.0"
}

variable "allowed_bastion_cidr_blocks" {
  description = "List of CIDR blocks to connect to bastion instances"
  type = list(string)
  default = ["0.0.0.0/0"] 
}

variable "public_subnet_tags" {
  type        = map(string)
  description = "Tags which specify the subnets to deploy bastion instances into"
}

variable "lb_type" {
  default ="application"
}

variable "key_name" {
  description = "Generated key name used to SSH into bastion and telemetry nodes"
}

variable "private_key_pem" {
  description = "Private key in PEM format generated from the tls_private_key resource"
}
