# Generate key pair only if create_key_pair is true
resource "tls_private_key" "ssh_key" {
  count = var.create_key_pair ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "web_server_key" {
  count = var.create_key_pair ? 1 : 0

  key_name   = "web-server-${random_id.server_suffix.hex}"
  public_key = tls_private_key.ssh_key[0].public_key_openssh

  tags = {
    Name = "web-server-key-${random_id.server_suffix.hex}"
  }
}

resource "local_file" "private_key" {
  count = var.create_key_pair ? 1 : 0

  content         = tls_private_key.ssh_key[0].private_key_pem
  filename        = "${path.module}/ssh-key-${random_id.server_suffix.hex}.pem"
  file_permission = "0600"
}

# Local value to determine which key to use
locals {
  key_pair_name = var.create_key_pair ? aws_key_pair.web_server_key[0].key_name : var.existing_key_pair_name
}
