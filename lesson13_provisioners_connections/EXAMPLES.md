# Provisioner Examples and Patterns

This document provides additional examples and patterns for OpenTofu provisioners beyond what's in the main lab.

## Table of Contents
1. [Connection Patterns](#connection-patterns)
2. [Advanced local-exec Examples](#advanced-local-exec-examples)
3. [Advanced remote-exec Examples](#advanced-remote-exec-examples)
4. [File Provisioner Patterns](#file-provisioner-patterns)
5. [Error Handling Strategies](#error-handling-strategies)
6. [null_resource Patterns](#null_resource-patterns)
7. [Real-World Use Cases](#real-world-use-cases)

---

## Connection Patterns

### Bastion Host (Jump Server) Connection

```hcl
resource "aws_instance" "private_server" {
  # ... instance configuration ...

  connection {
    type                = "ssh"
    user                = "ec2-user"
    private_key         = file("~/.ssh/id_rsa")
    host                = self.private_ip

    # Bastion configuration
    bastion_host        = aws_instance.bastion.public_ip
    bastion_user        = "ec2-user"
    bastion_private_key = file("~/.ssh/bastion_key")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Connected via bastion!'"]
  }
}
```

### Windows WinRM Connection

```hcl
resource "aws_instance" "windows_server" {
  ami           = "ami-windows-2022"
  instance_type = "t3.medium"

  user_data = <<-EOF
    <powershell>
    # Enable WinRM
    winrm quickconfig -q
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985
    </powershell>
  EOF

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password
    host     = self.public_ip
    port     = 5985
    https    = false
    insecure = true
    timeout  = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -Command \"Write-Host 'Hello from Windows!'\"",
      "powershell.exe -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools\""
    ]
  }
}
```

### Multiple Connection Blocks

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  # Default connection
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  # Use default connection
  provisioner "remote-exec" {
    inline = ["echo 'Using default connection'"]
  }

  # Override connection for specific provisioner
  provisioner "remote-exec" {
    inline = ["echo 'Using custom connection'"]

    connection {
      type        = "ssh"
      user        = "admin"  # Different user
      private_key = file("~/.ssh/admin_key")
      host        = self.public_ip
    }
  }
}
```

---

## Advanced local-exec Examples

### Update DNS Records

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  provisioner "local-exec" {
    command = <<-EOC
      aws route53 change-resource-record-sets \
        --hosted-zone-id ${var.zone_id} \
        --change-batch '{
          "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
              "Name": "web.example.com",
              "Type": "A",
              "TTL": 300,
              "ResourceRecords": [{"Value": "${self.public_ip}"}]
            }
          }]
        }'
    EOC
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOC
      aws route53 change-resource-record-sets \
        --hosted-zone-id ${var.zone_id} \
        --change-batch '{
          "Changes": [{
            "Action": "DELETE",
            "ResourceRecordSet": {
              "Name": "web.example.com",
              "Type": "A",
              "TTL": 300,
              "ResourceRecords": [{"Value": "${self.public_ip}"}]
            }
          }]
        }'
    EOC

    on_failure = continue
  }
}
```

### Trigger Webhook Notification

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  provisioner "local-exec" {
    command = "curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL -H 'Content-Type: application/json' -d '{\"text\":\"Instance ${self.id} deployed to ${self.public_ip}\"}'"

    on_failure = continue
  }
}
```

### Generate Ansible Inventory

```hcl
resource "aws_instance" "web" {
  count = 3
  # ... instance configuration ...
}

resource "null_resource" "ansible_inventory" {
  triggers = {
    instance_ids = join(",", aws_instance.web[*].id)
  }

  provisioner "local-exec" {
    command = <<-EOC
      cat > inventory.ini <<EOF
[webservers]
%{for instance in aws_instance.web~}
${instance.tags.Name} ansible_host=${instance.public_ip} ansible_user=ec2-user
%{endfor~}

[webservers:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
EOF
    EOC
  }
}
```

### Run Local Script with Parameters

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  provisioner "local-exec" {
    command     = "python3 ${path.module}/scripts/notify.py"
    interpreter = ["python3", "-u"]

    environment = {
      INSTANCE_ID   = self.id
      PUBLIC_IP     = self.public_ip
      REGION        = var.aws_region
      SLACK_WEBHOOK = var.slack_webhook_url
    }
  }
}
```

---

## Advanced remote-exec Examples

### Install Docker and Deploy Container

```hcl
resource "aws_instance" "docker_host" {
  # ... instance configuration ...

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",

      # Update system
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",

      # Add Docker GPG key
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",

      # Add Docker repository
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",

      # Install Docker
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",

      # Start Docker
      "sudo systemctl start docker",
      "sudo systemctl enable docker",

      # Add user to docker group
      "sudo usermod -aG docker ubuntu",

      # Pull and run container
      "sudo docker run -d -p 80:80 --name nginx nginx:latest",

      # Verify
      "sudo docker ps"
    ]
  }
}
```

### Configure PostgreSQL

```hcl
resource "aws_instance" "database" {
  # ... instance configuration ...

  provisioner "remote-exec" {
    inline = [
      # Install PostgreSQL
      "sudo dnf install -y postgresql15-server postgresql15-contrib",

      # Initialize database
      "sudo postgresql-setup --initdb",

      # Start and enable
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql",

      # Configure authentication
      "sudo sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf",

      # Create application database and user
      "sudo -u postgres psql -c \"CREATE DATABASE ${var.db_name};\"",
      "sudo -u postgres psql -c \"CREATE USER ${var.db_user} WITH PASSWORD '${var.db_password}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${var.db_name} TO ${var.db_user};\"",

      # Restart to apply changes
      "sudo systemctl restart postgresql"
    ]
  }
}
```

### Execute External Script

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  provisioner "remote-exec" {
    script = "${path.module}/scripts/complete-setup.sh"
  }
}
```

### Execute Multiple Scripts in Order

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/01-install-dependencies.sh",
      "${path.module}/scripts/02-configure-application.sh",
      "${path.module}/scripts/03-start-services.sh"
    ]
  }
}
```

---

## File Provisioner Patterns

### Upload Directory Structure

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Upload entire directory (contents)
  provisioner "file" {
    source      = "${path.module}/app/"  # Trailing slash = copy contents
    destination = "/tmp/app"
  }

  # Upload directory itself
  provisioner "file" {
    source      = "${path.module}/configs"  # No slash = copy directory
    destination = "/tmp"
  }
}
```

### Upload and Template Configuration

```hcl
resource "aws_instance" "app" {
  # ... instance configuration ...

  # Generate and upload templated config
  provisioner "file" {
    content = templatefile("${path.module}/templates/app.conf.tpl", {
      database_host     = aws_db_instance.main.endpoint
      database_name     = var.db_name
      redis_host        = aws_elasticache_cluster.redis.cache_nodes[0].address
      s3_bucket         = aws_s3_bucket.assets.id
      environment       = var.environment
      app_secret_key    = random_password.app_secret.result
    })
    destination = "/tmp/application.conf"
  }

  # Move to final location with correct permissions
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/application.conf /etc/myapp/app.conf",
      "sudo chown appuser:appuser /etc/myapp/app.conf",
      "sudo chmod 600 /etc/myapp/app.conf"
    ]
  }
}
```

### Upload SSL Certificates

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Upload certificate
  provisioner "file" {
    content     = tls_locally_signed_cert.web.cert_pem
    destination = "/tmp/server.crt"
  }

  # Upload private key
  provisioner "file" {
    content     = tls_private_key.web.private_key_pem
    destination = "/tmp/server.key"
  }

  # Upload CA certificate
  provisioner "file" {
    content     = tls_self_signed_cert.ca.cert_pem
    destination = "/tmp/ca.crt"
  }

  # Install certificates
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/server.crt /etc/pki/tls/certs/",
      "sudo mv /tmp/server.key /etc/pki/tls/private/",
      "sudo mv /tmp/ca.crt /etc/pki/ca-trust/source/anchors/",
      "sudo chmod 644 /etc/pki/tls/certs/server.crt",
      "sudo chmod 600 /etc/pki/tls/private/server.key",
      "sudo update-ca-trust"
    ]
  }
}
```

---

## Error Handling Strategies

### Retry Logic Pattern

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Critical operation - must succeed
  provisioner "remote-exec" {
    inline = [
      "echo 'Installing required packages...'",
      "for i in 1 2 3 4 5; do sudo yum install -y nginx && break || sleep 5; done"
    ]
  }

  # Optional operation - continue if it fails
  provisioner "remote-exec" {
    inline = ["sudo yum install -y optional-monitoring-agent"]
    on_failure = continue
  }
}
```

### Graceful Degradation

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Try to install from custom repository
  provisioner "remote-exec" {
    inline = [
      "echo 'Attempting custom repository install...'",
      "sudo yum install -y myapp-custom-repo"
    ]
    on_failure = continue
  }

  # Fallback to standard installation
  provisioner "remote-exec" {
    inline = [
      "if ! command -v myapp &> /dev/null; then",
      "  echo 'Custom install failed, using standard install...'",
      "  sudo yum install -y myapp-standard",
      "fi"
    ]
  }
}
```

### Destroy-Time Cleanup

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Deregister from service discovery before destruction
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "curl -X DELETE http://consul.service.consul:8500/v1/agent/service/deregister/web-${self.id}"
    ]
    on_failure = continue
  }

  # Archive logs before destruction
  provisioner "local-exec" {
    when    = destroy
    command = "ssh ec2-user@${self.public_ip} 'sudo tar -czf /tmp/logs-${self.id}.tar.gz /var/log/myapp' || true"
    on_failure = continue
  }

  # Download archived logs
  provisioner "local-exec" {
    when    = destroy
    command = "scp ec2-user@${self.public_ip}:/tmp/logs-${self.id}.tar.gz ./archive/ || true"
    on_failure = continue
  }
}
```

---

## null_resource Patterns

### Trigger on Variable Change

```hcl
resource "null_resource" "config_update" {
  triggers = {
    config_hash = sha256(jsonencode(var.app_config))
  }

  provisioner "remote-exec" {
    inline = ["sudo systemctl restart myapp"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.web.public_ip
    }
  }
}
```

### Trigger on File Change

```hcl
resource "null_resource" "deploy_script" {
  triggers = {
    script_hash = filemd5("${path.module}/scripts/deploy.sh")
  }

  provisioner "file" {
    source      = "${path.module}/scripts/deploy.sh"
    destination = "/tmp/deploy.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.web.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy.sh",
      "/tmp/deploy.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_instance.web.public_ip
    }
  }

  depends_on = [aws_instance.web]
}
```

### Periodic Execution Pattern

```hcl
resource "null_resource" "health_check" {
  triggers = {
    always_run = timestamp()  # Run on every apply
  }

  provisioner "local-exec" {
    command = "curl -f http://${aws_instance.web.public_ip}/health || exit 1"
  }
}
```

---

## Real-World Use Cases

### Bootstrap Configuration Management

```hcl
resource "aws_instance" "managed_node" {
  # ... instance configuration ...

  # Install Ansible dependencies
  provisioner "remote-exec" {
    inline = [
      "sudo dnf install -y python3 python3-pip",
      "sudo pip3 install ansible"
    ]
  }

  # Run Ansible playbook from local machine
  provisioner "local-exec" {
    command = <<-EOC
      sleep 30  # Wait for instance to be fully ready
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i '${self.public_ip},' \
        -u ec2-user \
        --private-key ${var.private_key_path} \
        ${path.module}/playbooks/configure.yml
    EOC
  }
}
```

### Deploy Application with Dependencies

```hcl
resource "aws_instance" "app_server" {
  # ... instance configuration ...

  # Upload application files
  provisioner "file" {
    source      = "${path.module}/../../app/dist"
    destination = "/tmp/app"
  }

  # Upload environment configuration
  provisioner "file" {
    content = templatefile("${path.module}/templates/.env.tpl", {
      db_host     = aws_db_instance.main.endpoint
      redis_host  = aws_elasticache_cluster.redis.cache_nodes[0].address
      s3_bucket   = aws_s3_bucket.assets.id
    })
    destination = "/tmp/.env"
  }

  # Deploy and start application
  provisioner "remote-exec" {
    inline = [
      # Install Node.js
      "curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -",
      "sudo yum install -y nodejs",

      # Set up application
      "sudo mkdir -p /opt/myapp",
      "sudo mv /tmp/app/* /opt/myapp/",
      "sudo mv /tmp/.env /opt/myapp/.env",
      "cd /opt/myapp && sudo npm install --production",

      # Create systemd service
      "sudo tee /etc/systemd/system/myapp.service > /dev/null <<EOF",
      "[Unit]",
      "Description=My Application",
      "After=network.target",
      "",
      "[Service]",
      "Type=simple",
      "User=ec2-user",
      "WorkingDirectory=/opt/myapp",
      "ExecStart=/usr/bin/node /opt/myapp/server.js",
      "Restart=always",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",

      # Start service
      "sudo systemctl daemon-reload",
      "sudo systemctl enable myapp",
      "sudo systemctl start myapp"
    ]
  }
}
```

These examples demonstrate advanced patterns and real-world use cases for OpenTofu provisioners. Remember that provisioners should be a last resort - always consider alternatives like user_data, custom AMIs, or configuration management tools first!
