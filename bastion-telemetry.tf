module "bastion" {
  source = "./bastion"

  bastion_count            = 3 # number of bastion nodes for benchmark-vault
  telemetry_count          = 1 # should only be 1 instance of grafana
  instance_type            = "t2.micro"
  vault_version            = "1.11.2"
  aws_region               = var.region                                # changed -nyoung
  resource_name_prefix     = module.vault-prereqs.resource_name_prefix # changed -nyoung
  vpc_id                   = module.vault-prereqs.vpc_id               # changed -nyoung
  public_subnet_tags       = { Vault = "public" }                      # changed -nyoung
  vault_lb_sg_id           = module.vault-ent-starter.vault_lb_sg_id   # changed -nyoung
  secrets_manager_arn      = module.vault-prereqs.secrets_manager_arn  # changed -nyoung
  vault_lb_dns_name        = aws_route53_record.vault_lb.fqdn # changed to match Route53 A record and cert name -nyoung
  aws_iam_instance_profile = module.vault-ent-starter.aws_iam_instance_profile
  key_name                 = aws_key_pair.awskey.key_name           # changed -nyoung
  private_key_pem          = tls_private_key.awskey.private_key_pem # changed -nyoung

}

output "benchmark_public_ip" {
  value       = module.bastion.bastion_public_ip
}

output "telemetry_public_ip" {
  value       = module.bastion.telemetry_public_ip
}