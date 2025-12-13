# =============================================================================
# OpenTofu Provisioners & Connections Lab
# =============================================================================
# This configuration demonstrates:
# - local-exec provisioner
# - remote-exec provisioner
# - file provisioner
# - Connection blocks with SSH
# - Error handling (on_failure, when)
# =============================================================================

# -----------------------------------------------------------------------------
# Generate SSH Key Pair (if not using existing key)
# -----------------------------------------------------------------------------
resource "tls_private_key" "ssh_key" {
  count     = var.use_existing_key ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "web_server_key" {
  key_name   = var.use_existing_key ? var.existing_key_name : "web-server-key-${random_id.suffix.hex}"
  public_key = var.use_existing_key ? "" : tls_private_key.ssh_key[0].public_key_openssh

  tags = {
    Name        = "web-server-keypair-${random_id.suffix.hex}"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }

  lifecycle {
    ignore_changes = [public_key]
  }
}

# Save private key locally (only if generated)
resource "local_file" "private_key" {
  count           = var.use_existing_key ? 0 : 1
  content         = tls_private_key.ssh_key[0].private_key_pem
  filename        = "${path.module}/ssh-key-${random_id.suffix.hex}.pem"
  file_permission = "0600"

  # Example: local-exec on creation and destruction
  provisioner "local-exec" {
    command = "echo 'SSH private key generated at: ${self.filename}' >> ${path.module}/provisioner-log.txt"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'SSH private key destroyed: ${self.filename}' >> ${path.module}/provisioner-log.txt"
  }
}

# -----------------------------------------------------------------------------
# Random ID for unique naming
# -----------------------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Security Group for Web Server
# -----------------------------------------------------------------------------
resource "aws_security_group" "web_server_sg" {
  name_prefix = "provisioner-lab-${random_id.suffix.hex}-"
  description = "Security group for provisioner lab - SSH and HTTP access"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP access
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "provisioner-lab-sg-${random_id.suffix.hex}"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance with Comprehensive Provisioner Examples
# -----------------------------------------------------------------------------
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.web_server_key.key_name

  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Basic user data for initial setup
  user_data = <<-EOF
              #!/bin/bash
              # Basic setup via user_data (preferred for simple initialization)
              yum update -y
              yum install -y httpd git curl wget

              # Create basic directory structure
              mkdir -p /var/www/html
              mkdir -p /opt/app

              # Set permissions
              chown -R ec2-user:ec2-user /opt/app
              EOF

  tags = {
    Name        = "provisioner-lab-${random_id.suffix.hex}"
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Lab         = "Provisioners"
  }

  # ==========================================================================
  # CONNECTION BLOCK - Applies to all provisioners in this resource
  # ==========================================================================
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.use_existing_key ? file(var.existing_key_path) : tls_private_key.ssh_key[0].private_key_pem
    host        = self.public_ip
    timeout     = "5m"
  }

  # ==========================================================================
  # PROVISIONER 1: local-exec - Log instance details locally
  # ==========================================================================
  provisioner "local-exec" {
    command = "echo '${self.id},${self.public_ip},${self.private_ip},${timestamp()}' >> ${path.module}/inventory.txt"

    environment = {
      INSTANCE_ID = self.id
      PUBLIC_IP   = self.public_ip
    }
  }

  # ==========================================================================
  # PROVISIONER 2: local-exec - Generate SSH config entry
  # ==========================================================================
  provisioner "local-exec" {
    command = <<-EOC
      echo "Host provisioner-lab-${random_id.suffix.hex}" >> ${path.module}/ssh-config-entry.txt
      echo "  HostName ${self.public_ip}" >> ${path.module}/ssh-config-entry.txt
      echo "  User ec2-user" >> ${path.module}/ssh-config-entry.txt
      echo "  IdentityFile ${var.use_existing_key ? var.existing_key_path : "${path.module}/ssh-key-${random_id.suffix.hex}.pem"}" >> ${path.module}/ssh-config-entry.txt
      echo "  StrictHostKeyChecking no" >> ${path.module}/ssh-config-entry.txt
      echo "" >> ${path.module}/ssh-config-entry.txt
    EOC

    on_failure = continue  # Don't fail if this optional step fails
  }

  # ==========================================================================
  # PROVISIONER 3: remote-exec - Wait for instance to be ready
  # ==========================================================================
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Instance is ready!'"
    ]
  }

  # ==========================================================================
  # PROVISIONER 4: file - Upload custom HTML content
  # ==========================================================================
  provisioner "file" {
    content = templatefile("${path.module}/scripts/index.html.tpl", {
      instance_id   = self.id
      instance_type = self.instance_type
      public_ip     = self.public_ip
      private_ip    = self.private_ip
      region        = var.aws_region
      environment   = var.environment
      random_suffix = random_id.suffix.hex
    })
    destination = "/tmp/index.html"
  }

  # ==========================================================================
  # PROVISIONER 5: file - Upload nginx configuration script
  # ==========================================================================
  provisioner "file" {
    source      = "${path.module}/scripts/setup-web-server.sh"
    destination = "/tmp/setup-web-server.sh"
  }

  # ==========================================================================
  # PROVISIONER 6: file - Upload application configuration
  # ==========================================================================
  provisioner "file" {
    content = jsonencode({
      app_name    = "provisioner-lab"
      environment = var.environment
      version     = "1.0.0"
      instance_id = self.id
      timestamp   = timestamp()
    })
    destination = "/tmp/app-config.json"
  }

  # ==========================================================================
  # PROVISIONER 7: remote-exec - Execute setup script
  # ==========================================================================
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup-web-server.sh",
      "sudo /tmp/setup-web-server.sh"
    ]
  }

  # ==========================================================================
  # PROVISIONER 8: remote-exec - Configure web server
  # ==========================================================================
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/index.html /var/www/html/index.html",
      "sudo chown apache:apache /var/www/html/index.html",
      "sudo systemctl restart httpd",
      "sudo systemctl status httpd"
    ]
  }

  # ==========================================================================
  # PROVISIONER 9: remote-exec - Install monitoring agent (optional)
  # ==========================================================================
  provisioner "remote-exec" {
    inline = [
      "echo 'Installing optional monitoring agent...'",
      "sudo yum install -y amazon-cloudwatch-agent || echo 'CloudWatch agent installation failed'"
    ]

    on_failure = continue  # Don't fail if monitoring agent fails
  }

  # ==========================================================================
  # PROVISIONER 10: local-exec - Send notification (simulated)
  # ==========================================================================
  provisioner "local-exec" {
    command = "echo 'Instance ${self.id} deployed successfully at ${self.public_ip}' >> ${path.module}/deployment-notifications.txt"

    environment = {
      INSTANCE_ID        = self.id
      PUBLIC_IP          = self.public_ip
      WEB_URL            = "http://${self.public_ip}"
      DEPLOYMENT_TIME    = timestamp()
    }
  }

  # ==========================================================================
  # DESTROY-TIME PROVISIONERS
  # ==========================================================================

  # Gracefully stop web server before destruction
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "echo 'Stopping web server gracefully...'",
      "sudo systemctl stop httpd || true",
      "sleep 5"
    ]

    on_failure = continue  # Don't block destruction if this fails

    # Override connection for destroy (self attributes may not be available)
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.use_existing_key ? file(var.existing_key_path) : file("${path.module}/ssh-key-${random_id.suffix.hex}.pem")
      host        = self.public_ip
      timeout     = "2m"
    }
  }

  # Log destruction locally
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} destroyed at ${timestamp()}' >> ${path.module}/destruction-log.txt"

    on_failure = continue
  }

  # Remove from inventory
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i.bak '/${self.id}/d' ${path.module}/inventory.txt || true"

    on_failure = continue
  }

  depends_on = [
    aws_security_group.web_server_sg
  ]
}

# -----------------------------------------------------------------------------
# Null Resource Example - Standalone Provisioners
# -----------------------------------------------------------------------------
# Use null_resource when you need provisioners without managing infrastructure
# or when you want to trigger provisioners based on specific changes

resource "null_resource" "post_deployment_config" {
  # Triggers determine when this null_resource should be recreated
  triggers = {
    instance_id        = aws_instance.web_server.id
    configuration_hash = filemd5("${path.module}/scripts/post-deploy.sh")
  }

  # Connection to the instance
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.use_existing_key ? file(var.existing_key_path) : tls_private_key.ssh_key[0].private_key_pem
    host        = aws_instance.web_server.public_ip
    timeout     = "5m"
  }

  # Upload and execute post-deployment script
  provisioner "file" {
    source      = "${path.module}/scripts/post-deploy.sh"
    destination = "/tmp/post-deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/post-deploy.sh",
      "/tmp/post-deploy.sh"
    ]

    on_failure = continue
  }

  # Local notification
  provisioner "local-exec" {
    command = "echo 'Post-deployment configuration completed for ${aws_instance.web_server.id}' >> ${path.module}/provisioner-log.txt"
  }

  depends_on = [aws_instance.web_server]
}

# -----------------------------------------------------------------------------
# Example: Conditional Provisioner Execution
# -----------------------------------------------------------------------------
resource "null_resource" "conditional_config" {
  count = var.enable_advanced_config ? 1 : 0

  triggers = {
    instance_id = aws_instance.web_server.id
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.use_existing_key ? file(var.existing_key_path) : tls_private_key.ssh_key[0].private_key_pem
    host        = aws_instance.web_server.public_ip
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Running advanced configuration...'",
      "sudo /opt/app/advanced-setup.sh || true"
    ]

    on_failure = continue
  }
}
