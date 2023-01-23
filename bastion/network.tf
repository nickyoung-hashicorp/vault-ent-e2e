data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnet_ids" "vault" {
  vpc_id = data.aws_vpc.selected.id
  tags   = var.public_subnet_tags
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.resource_name_prefix}-bastion-sg"
  description = "Firewall for the operator bastion instance"
  vpc_id = var.vpc_id
  tags = {
    Name        = "${var.resource_name_prefix}-bastion-sg"
    Description = "Bastion Host"
  }
}

resource "aws_security_group_rule" "bastion_allow_22" {
  security_group_id = aws_security_group.bastion.id
  type = "ingress"
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_blocks = var.allowed_bastion_cidr_blocks
  description = "Allow SSH traffic."
}

resource "aws_security_group_rule" "bastion_allow_outbound" {
  security_group_id = aws_security_group.bastion.id
  type = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow any outbound traffic."
}

# resource "aws_security_group_rule" "vault_lb_outbound_to_bastion" {
#   count                    = var.lb_type == "application" ? 1 : 0
#   description              = "Allow outbound traffic from load balancer to Vault nodes on port 8200"
#   security_group_id        = aws_security_group.bastion.id
#   type                     = "egress"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   cidr_blocks = var.allowed_bastion_cidr_blocks
# }
