# OpenTofu Provisioners & Connections Lab

## Overview
This lab provides comprehensive training on OpenTofu provisioners and connections. You'll learn how to configure EC2 instances post-deployment, handle errors, and establish SSH connections for remote execution.

## Table of Contents
1. [Provisioners Explained](#provisioners-explained)
2. [Connection Blocks & SSH Setup](#connection-blocks--ssh-setup)
3. [Error Handling](#error-handling)
4. [Lab Exercises](#lab-exercises)
5. [Deployment Instructions](#deployment-instructions)
6. [Best Practices](#best-practices)

---

## Provisioners Explained

### What Are Provisioners?
Provisioners are a **last resort** in OpenTofu/Terraform. They allow you to execute scripts or commands on local or remote machines as part of the resource creation or destruction process.

**Important:** Provisioners are considered a last resort because:
- They break declarative infrastructure model
- Error handling is complex
- State management becomes difficult
- Better alternatives exist (user_data, cloud-init, configuration management tools)

### Types of Provisioners

#### 1. local-exec Provisioner
Executes commands on the **machine running OpenTofu** (your workstation or CI/CD server).

**Use Cases:**
- Update local inventory files
- Trigger external APIs
- Run local scripts
- Generate configuration files

**Example:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> inventory.txt"

    # Working directory for command execution
    working_dir = "/tmp"

    # Environment variables
    environment = {
      PUBLIC_IP = self.public_ip
      INSTANCE_ID = self.id
    }
  }
}
```

**Key Parameters:**
- `command` (required): Command to execute
- `working_dir`: Directory to run command from
- `environment`: Map of environment variables
- `interpreter`: Custom command interpreter (default: ["/bin/sh", "-c"] on Linux)

#### 2. remote-exec Provisioner
Executes commands on the **remote resource** after it's created.

**Use Cases:**
- Install software packages
- Configure services
- Run initialization scripts
- Bootstrap configuration management tools

**Example:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  key_name      = "my-key"

  provisioner "remote-exec" {
    # Inline commands
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }

  # Alternative: Run a single script
  # provisioner "remote-exec" {
  #   script = "path/to/setup.sh"
  # }

  # Alternative: Run multiple scripts
  # provisioner "remote-exec" {
  #   scripts = [
  #     "scripts/install.sh",
  #     "scripts/configure.sh"
  #   ]
  # }
}
```

**Key Parameters:**
- `inline`: List of command strings
- `script`: Path to local script to copy and execute
- `scripts`: List of local scripts to copy and execute

#### 3. file Provisioner
Copies files or directories from the **local machine** to the **remote resource**.

**Use Cases:**
- Upload configuration files
- Deploy application code
- Transfer certificates/keys
- Copy scripts before execution

**Example:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  key_name      = "my-key"

  # Upload a single file
  provisioner "file" {
    source      = "configs/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  # Upload entire directory
  provisioner "file" {
    source      = "configs/"  # Trailing slash copies contents
    destination = "/tmp/configs"
  }

  # Upload using content
  provisioner "file" {
    content     = templatefile("templates/app.conf.tpl", {
      db_host = aws_db_instance.main.endpoint
    })
    destination = "/tmp/app.conf"
  }
}
```

**Key Parameters:**
- `source`: Local file or directory path
- `destination`: Remote path (must be absolute)
- `content`: Direct content to write to destination

---

## Connection Blocks & SSH Setup

### Connection Block Syntax
Connection blocks define how OpenTofu connects to remote resources for `remote-exec` and `file` provisioners.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  # Connection block - can be at resource level (applies to all provisioners)
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Connected!'"]
  }
}
```

### Connection Parameters

#### SSH Connection Type
```hcl
connection {
  type = "ssh"  # Default type

  # Authentication
  user        = "ec2-user"
  password    = "password"              # Not recommended!
  private_key = file("~/.ssh/id_rsa")  # Recommended
  certificate = file("~/.ssh/id_rsa-cert.pub")

  # Connection details
  host        = self.public_ip
  port        = 22
  timeout     = "5m"

  # Advanced options
  agent                = true           # Use SSH agent
  agent_identity       = "key_name"     # Specific key from agent
  host_key             = "ssh-rsa AAAA..."

  # Bastion/Jump host
  bastion_host        = "bastion.example.com"
  bastion_user        = "bastion-user"
  bastion_password    = "bastion-pass"
  bastion_private_key = file("~/.ssh/bastion_key")
  bastion_port        = 22
}
```

#### WinRM Connection Type (Windows)
```hcl
connection {
  type     = "winrm"
  user     = "Administrator"
  password = "SuperSecret123!"
  host     = self.public_ip
  port     = 5986
  https    = true
  insecure = true
  timeout  = "10m"
}
```

### SSH Setup Best Practices

#### 1. Key Pair Management
```hcl
# Generate key pair using TLS provider
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save private key locally (be careful with state!)
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/deployer-key.pem"
  file_permission = "0600"
}

# Use in instance
resource "aws_instance" "web" {
  key_name = aws_key_pair.deployer.key_name

  connection {
    private_key = tls_private_key.ssh_key.private_key_pem
    user        = "ec2-user"
    host        = self.public_ip
  }
}
```

#### 2. Using Existing Keys
```hcl
variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
  sensitive   = true
}

connection {
  private_key = file(var.ssh_private_key_path)
  user        = "ec2-user"
  host        = self.public_ip
}
```

#### 3. Waiting for SSH Availability
```hcl
provisioner "remote-exec" {
  # Wait for SSH to become available
  inline = ["echo 'SSH is ready!'"]

  connection {
    timeout = "5m"  # Wait up to 5 minutes
  }
}
```

---

## Error Handling

### on_failure Parameter
Controls what happens when a provisioner fails.

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo systemctl start nginx"
  ]

  on_failure = continue  # Options: continue, fail (default)
}
```

**Options:**
- `fail` (default): Stop and mark resource as tainted
- `continue`: Log error but continue with creation

**Example with continue:**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  # Critical provisioner - must succeed
  provisioner "remote-exec" {
    inline = ["sudo yum install -y nginx"]
    # on_failure = fail  # This is the default
  }

  # Optional provisioner - continue if it fails
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y optional-package-that-might-not-exist"
    ]
    on_failure = continue
  }
}
```

### when Parameter
Controls when a provisioner runs.

```hcl
provisioner "local-exec" {
  when    = destroy  # Options: create (default), destroy
  command = "echo 'Resource is being destroyed'"
}
```

**Options:**
- `create` (default): Run during resource creation
- `destroy`: Run during resource destruction

**Example: Cleanup on Destroy**
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  # Run on creation
  provisioner "local-exec" {
    command = "echo '${self.id},${self.public_ip}' >> inventory.csv"
  }

  # Run on destruction
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/${self.id}/d' inventory.csv"
  }

  # Deregister from load balancer before destroy
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "curl -X DELETE http://loadbalancer/api/deregister/${self.id}"
    ]
  }
}
```

### Combined Error Handling
```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  # Try to drain connections gracefully, but don't fail destroy if it errors
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue

    inline = [
      "sudo systemctl stop nginx",
      "sleep 30"  # Wait for connections to drain
    ]

    connection {
      timeout = "2m"
    }
  }
}
```

### Null Resource for Standalone Provisioners
When you need provisioners without managing infrastructure:

```hcl
resource "null_resource" "configuration" {
  # Trigger re-run when instance changes
  triggers = {
    instance_id = aws_instance.web.id
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /opt/app/configure.sh"
    ]

    connection {
      host = aws_instance.web.public_ip
      user = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}
```

---

## Lab Exercises

### What This Lab Creates
1. **EC2 Instance** with Amazon Linux 2023
2. **Security Group** with SSH and HTTP access
3. **SSH Key Pair** for authentication
4. **Web Server** configured via provisioners
5. **Local Inventory** file tracking instances
6. **Custom Application** deployed via file provisioner

### Provisioner Demonstrations

#### 1. local-exec Examples
- Log instance details to local file
- Update local inventory
- Trigger webhook notification
- Generate SSH config entry

#### 2. remote-exec Examples
- Install and configure Nginx
- Deploy application files
- Set up monitoring agent
- Configure firewall rules

#### 3. file Examples
- Upload custom web content
- Deploy SSL certificates
- Copy configuration templates
- Transfer application binaries

#### 4. Error Handling Examples
- Optional package installation
- Graceful service shutdown on destroy
- Retry logic simulation
- Cleanup operations

---

## Deployment Instructions

### Prerequisites
1. AWS credentials configured
2. OpenTofu installed (v1.6+)
3. SSH key pair available or will be generated
4. Security group allows SSH (port 22) from your IP

### Option 1: Generate New SSH Key
```bash
# Initialize
cd lesson13_provisioners_connections
tofu init

# Plan and review
tofu plan

# Apply
tofu apply

# SSH to instance
SSH_COMMAND=$(tofu output -raw ssh_command)
eval $SSH_COMMAND

# Or manually
ssh -i ./ssh-key-*.pem ec2-user@$(tofu output -raw instance_public_ip)
```

### Option 2: Use Existing SSH Key
```bash
# Set your key path
export TF_VAR_existing_key_path="~/.ssh/my-key.pem"
export TF_VAR_existing_key_name="my-aws-key-name"

# Apply with existing key
tofu apply -var="use_existing_key=true"

# SSH using your key
ssh -i ~/.ssh/my-key.pem ec2-user@$(tofu output -raw instance_public_ip)
```

### Verify Deployment
```bash
# Check web server
WEB_URL=$(tofu output -raw web_url)
curl $WEB_URL

# View local inventory
cat inventory.txt

# Check SSH config generated
cat ssh-config-entry.txt
```

### Cleanup
```bash
# Destroy infrastructure
# Note: Destroy-time provisioners will run
tofu destroy

# Verify local files cleaned up
ls -la *.txt
```

---

## Best Practices

### When to Use Provisioners
1. **Last Resort**: Try these alternatives first:
   - `user_data` for initial configuration
   - Cloud-init for complex bootstrapping
   - Custom AMIs with pre-installed software
   - Configuration management tools (Ansible, Chef, Puppet)
   - Container images with pre-configured environments

2. **Acceptable Use Cases**:
   - Bootstrapping configuration management agents
   - Running scripts that must execute after all resources are created
   - Cleanup operations during resource destruction
   - Triggering external systems

### Security Best Practices
1. **Never** store private keys in version control
2. **Always** use variables for sensitive data
3. **Mark** sensitive variables appropriately
4. **Use** IAM roles instead of embedding credentials
5. **Limit** SSH access to specific IP ranges
6. **Rotate** SSH keys regularly
7. **Avoid** using password authentication

### Performance Best Practices
1. **Minimize** provisioner usage
2. **Use** `user_data` for simple bootstrapping
3. **Implement** proper timeouts
4. **Add** retry logic where appropriate
5. **Consider** null_resource for re-runnable provisioners

### Error Handling Best Practices
1. **Set** appropriate timeouts for all connections
2. **Use** `on_failure = continue` for non-critical operations
3. **Implement** cleanup provisioners with `when = destroy`
4. **Add** logging for troubleshooting
5. **Test** provisioners thoroughly before production use

### Debugging Tips
```bash
# Enable verbose SSH logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
tofu apply

# Test SSH connectivity manually
ssh -v -i key.pem ec2-user@instance-ip

# Check cloud-init logs on instance
ssh ec2-user@instance-ip
sudo cat /var/log/cloud-init-output.log

# Verify security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

---

## Common Issues and Solutions

### Issue 1: SSH Timeout
**Problem:** `timeout - last error: dial tcp x.x.x.x:22: i/o timeout`

**Solutions:**
- Verify security group allows SSH from your IP
- Check instance has public IP
- Ensure instance is in running state
- Increase timeout value
- Verify network ACLs

### Issue 2: Permission Denied (publickey)
**Problem:** `Permission denied (publickey)`

**Solutions:**
- Verify correct private key file
- Check key file permissions (should be 0600)
- Ensure correct username (ec2-user, ubuntu, admin)
- Verify key pair attached to instance

### Issue 3: Connection Refused
**Problem:** `connect: connection refused`

**Solutions:**
- Wait for instance to fully boot
- Check SSH service is running on instance
- Verify correct port (default 22)
- Check firewall rules on instance

### Issue 4: Provisioner Fails, Resource Tainted
**Problem:** Resource marked as tainted after provisioner failure

**Solutions:**
- Use `on_failure = continue` for non-critical provisioners
- Fix the provisioner script
- Use `tofu untaint` if resource is actually healthy
- Re-run `tofu apply`

---

## Additional Resources

### Documentation
- [OpenTofu Provisioners](https://opentofu.org/docs/language/resources/provisioners/)
- [Connection Block](https://opentofu.org/docs/language/resources/provisioners/connection/)
- [AWS EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)

### Alternative Approaches
- **Cloud-init**: More powerful than user_data
- **Packer**: Build custom AMIs with software pre-installed
- **Ansible**: Configuration management after infrastructure creation
- **AWS Systems Manager**: Run commands without SSH

### Next Steps
- Explore custom AMI creation with Packer
- Learn cloud-init for complex bootstrapping
- Study configuration management tools
- Implement proper CI/CD pipelines
- Practice blue-green deployments

---

## Lab Summary

In this lab, you've learned:
- ✅ Three types of provisioners: local-exec, remote-exec, file
- ✅ How to configure SSH connections
- ✅ Error handling with on_failure and when
- ✅ Best practices and common pitfalls
- ✅ Real-world EC2 instance configuration
- ✅ Debugging and troubleshooting techniques

**Remember:** Provisioners are a last resort. Always consider declarative alternatives first!
