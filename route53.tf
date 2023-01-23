### Route53 - DNS A Record for Vault's Internal Load Balancer
### Includes all created resources, variables, and outputs

# retrieve existing hosted zone
data "aws_route53_zone" "zone" {
  name = var.hosted_zone
  #   private_zone = true # default is a public hosted zone.  Uncomment this line if using a private zone.
}

resource "aws_route53_record" "vault_lb" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.route53_a_record
  type    = "A"

  alias {
    name                   = module.vault-ent-starter.vault_lb_dns_name
    zone_id                = module.vault-ent-starter.vault_lb_zone_id
    evaluate_target_health = true
  }
}

variable "route53_a_record" {
  default     = "vault.nyoung.aws.hashidemos.io"
  description = "FQDN of the Route53 A record that will resolve to the internal load balancer for the Vault cluster."
}

variable "hosted_zone" {
  default     = "nyoung.aws.hashidemos.io"
  description = "An existing hosted zone within which a Route53 A record can be created."
}

output "route53_fqdn" {
  value = aws_route53_record.vault_lb.fqdn
}