### SSH Key
### Includes all created resources, variables, and outputs

resource "random_id" "name" {
  byte_length = 4
}

resource "aws_key_pair" "awskey" {
  key_name   = "awskwy-${random_id.name.hex}"
  public_key = tls_private_key.awskey.public_key_openssh
}

resource "tls_private_key" "awskey" {
  algorithm = "RSA"
}

resource "null_resource" "awskey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.awskey.private_key_pem}\" > awskey.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 awskey.pem"
  }
}

output "key_name" {
  value = aws_key_pair.awskey.key_name
}
