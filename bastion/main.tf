data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion" {
  count                   = var.bastion_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type 
  key_name                = var.key_name # changed -nyoung
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = sort(data.aws_subnet_ids.vault.ids)[0]
  iam_instance_profile    = var.aws_iam_instance_profile
  associate_public_ip_address = true

  tags = {
    Name        = "${var.resource_name_prefix}-vault-bastion"
    Description = "Bastion Node"
  }

  user_data = templatefile("${path.module}/configs/bastion.tpl", {
    vault_version       = var.vault_version
    secrets_manager_arn = var.secrets_manager_arn
    aws_region          = var.aws_region
    vault_lb_dns_name   = var.vault_lb_dns_name
    private_key_name    = var.private_key_pem # changed -nyoung, originally tls_private_key.awskey.private_key_pem
  })
}

resource "aws_instance" "telemetry" {
  count                   = var.telemetry_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.instance_type
  key_name                = var.key_name # changed -nyoung
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = sort(data.aws_subnet_ids.vault.ids)[0]
  iam_instance_profile    = var.aws_iam_instance_profile
  associate_public_ip_address = true

  tags = {
    Name        = "${var.resource_name_prefix}-vault-bastion"
    Description = "Telemetry Node"
  }

  user_data = templatefile("${path.module}/configs/telemetry.tpl", {
    vault_version       = var.vault_version
    secrets_manager_arn = var.secrets_manager_arn
    aws_region          = var.aws_region
    vault_lb_dns_name   = var.vault_lb_dns_name
    private_key_name    = var.private_key_pem # changed -nyoung, originally tls_private_key.awskey.private_key_pem
  })
}
