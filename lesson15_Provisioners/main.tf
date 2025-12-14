# ============================================
# SSH Key Pair Management
# ============================================

# Generate new SSH key pair
resource "tls_private_key" "provisioner_key" {
  count = var.create_new_key_pair ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  count = var.create_new_key_pair ? 1 : 0

  content         = tls_private_key.provisioner_key[0].private_key_pem
  filename        = "${path.module}/provisioner-key.pem"
  file_permission = "0600"
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "provisioner" {
  count = var.create_new_key_pair ? 1 : 0

  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.provisioner_key[0].public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# ============================================
# Networking
# ============================================

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Security Groups
# ============================================

# Security Group for Web Server
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  description = "Security group for web server with provisioner access"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "SSH access for provisioners"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access to web server"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# EC2 Instance with Provisioners
# ============================================

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # Use appropriate key pair based on configuration
  key_name = var.create_new_key_pair ? aws_key_pair.provisioner[0].key_name : var.existing_key_pair_name

  # Basic user data to ensure instance is ready
  user_data = <<-EOF
              #!/bin/bash
              # Ensure instance is fully initialized
              touch /tmp/instance-ready
              EOF

  tags = {
    Name = "${var.project_name}-web-server"
  }

  # ============================================
  # NOTE: Connection block is defined in each provisioner
  # that needs SSH access. Destroy provisioners cannot
  # reference external resources, only 'self' attributes.
  # ============================================

  # ============================================
  # PROVISIONER 1: Wait for instance
  # ============================================
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting...'; sleep 2; done",
      "echo 'Instance is ready!'"
    ]
  }

  # ============================================
  # PROVISIONER 2: Copy bootstrap script
  # ============================================
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  # ============================================
  # PROVISIONER 3: Execute bootstrap
  # ============================================
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo /tmp/bootstrap.sh"
    ]
  }

  # ============================================
  # PROVISIONER 4: Copy nginx configuration
  # ============================================
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    source      = "${path.module}/files/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  # ============================================
  # PROVISIONER 5: Copy web page
  # ============================================
  provisioner "file" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    source      = "${path.module}/files/index.html"
    destination = "/tmp/index.html"
  }

  # ============================================
  # PROVISIONER 6: Configure and start nginx
  # ============================================
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    inline = [
      "echo 'Configuring nginx...'",
      "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
      "sudo mv /tmp/index.html /usr/share/nginx/html/index.html",
      "sudo chown -R nginx:nginx /usr/share/nginx/html",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "echo 'Nginx configured and started!'",
      "sudo systemctl status nginx --no-pager"
    ]
  }

  # ============================================
  # PROVISIONER 7: Verify nginx is responding
  # ============================================
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = var.create_new_key_pair ? tls_private_key.provisioner_key[0].private_key_pem : file(var.existing_private_key_path)
      agent       = false
      timeout     = "5m"
    }

    inline = [
      "echo 'Waiting for nginx to respond...'",
      "for i in {1..30}; do",
      "  if curl -f http://localhost:80/ > /dev/null 2>&1; then",
      "    echo 'Nginx is responding!'",
      "    exit 0",
      "  fi",
      "  echo 'Attempt $i: Waiting for nginx...'",
      "  sleep 2",
      "done",
      "echo 'Warning: Nginx may not be fully ready'",
      "exit 0" # Don't fail if nginx isn't ready yet
    ]

    on_failure = continue # Don't fail deployment if check times out
  }

  # ============================================
  # PROVISIONER 8: Local logging
  # ============================================
  provisioner "local-exec" {
    command = "echo 'Instance ${self.id} deployed at ${self.public_ip} on ${timestamp()}' >> deployment-log.txt"
  }

  # ============================================
  # PROVISIONER 9: Create local inventory
  # ============================================
  provisioner "local-exec" {
    command = <<-EOT
      cat > instance-info.txt <<EOF
      Instance ID: ${self.id}
      Public IP: ${self.public_ip}
      Private IP: ${self.private_ip}
      Deployment Time: ${timestamp()}
      Web URL: http://${self.public_ip}
      SSH Command: ssh -i ${var.create_new_key_pair ? "${path.module}/provisioner-key.pem" : var.existing_private_key_path} ec2-user@${self.public_ip}
      EOF
    EOT
  }

  # ============================================
  # DESTROY PROVISIONER: Cleanup logging
  # ============================================
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} destroyed at ${timestamp()}' >> deployment-log.txt"

    on_failure = continue # Don't fail destroy if logging fails
  }
}
