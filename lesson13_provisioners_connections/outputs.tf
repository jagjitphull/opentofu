# =============================================================================
# Outputs for Provisioners & Connections Lab
# =============================================================================

# -----------------------------------------------------------------------------
# Instance Information
# -----------------------------------------------------------------------------
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.web_server.instance_state
}

# -----------------------------------------------------------------------------
# Web Server Access
# -----------------------------------------------------------------------------
output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "web_url_dns" {
  description = "URL to access the web server via DNS"
  value       = "http://${aws_instance.web_server.public_dns}"
}

# -----------------------------------------------------------------------------
# SSH Connection Information
# -----------------------------------------------------------------------------
output "ssh_user" {
  description = "SSH username for connecting to the instance"
  value       = "ec2-user"
}

output "ssh_command" {
  description = "Complete SSH command to connect to the instance"
  value = var.use_existing_key ? "ssh -i ${var.existing_key_path} ec2-user@${aws_instance.web_server.public_ip}" : "ssh -i ${path.module}/ssh-key-${random_id.suffix.hex}.pem ec2-user@${aws_instance.web_server.public_ip}"
}

output "ssh_key_path" {
  description = "Path to the SSH private key"
  value       = var.use_existing_key ? var.existing_key_path : "${path.module}/ssh-key-${random_id.suffix.hex}.pem"
  sensitive   = true
}

output "key_pair_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.web_server_key.key_name
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_server_sg.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.web_server_sg.name
}

# -----------------------------------------------------------------------------
# AMI Information
# -----------------------------------------------------------------------------
output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.web_server.ami
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = data.aws_ami.amazon_linux_2023.name
}

output "ami_description" {
  description = "Description of the AMI used"
  value       = data.aws_ami.amazon_linux_2023.description
}

# -----------------------------------------------------------------------------
# Resource Identifiers
# -----------------------------------------------------------------------------
output "random_suffix" {
  description = "Random suffix used for resource naming"
  value       = random_id.suffix.hex
}

output "resource_prefix" {
  description = "Prefix used for resource names"
  value       = "provisioner-lab-${random_id.suffix.hex}"
}

# -----------------------------------------------------------------------------
# Provisioner Artifacts
# -----------------------------------------------------------------------------
output "provisioner_log_files" {
  description = "List of log files created by provisioners"
  value = [
    "${path.module}/inventory.txt",
    "${path.module}/ssh-config-entry.txt",
    "${path.module}/deployment-notifications.txt",
    "${path.module}/provisioner-log.txt"
  ]
}

# -----------------------------------------------------------------------------
# Quick Reference Commands
# -----------------------------------------------------------------------------
output "helpful_commands" {
  description = "Helpful commands for interacting with the deployed instance"
  value = {
    ssh              = var.use_existing_key ? "ssh -i ${var.existing_key_path} ec2-user@${aws_instance.web_server.public_ip}" : "ssh -i ${path.module}/ssh-key-${random_id.suffix.hex}.pem ec2-user@${aws_instance.web_server.public_ip}"
    web_test         = "curl http://${aws_instance.web_server.public_ip}"
    check_httpd      = var.use_existing_key ? "ssh -i ${var.existing_key_path} ec2-user@${aws_instance.web_server.public_ip} 'sudo systemctl status httpd'" : "ssh -i ${path.module}/ssh-key-${random_id.suffix.hex}.pem ec2-user@${aws_instance.web_server.public_ip} 'sudo systemctl status httpd'"
    view_logs        = var.use_existing_key ? "ssh -i ${var.existing_key_path} ec2-user@${aws_instance.web_server.public_ip} 'sudo tail -f /var/log/httpd/access_log'" : "ssh -i ${path.module}/ssh-key-${random_id.suffix.hex}.pem ec2-user@${aws_instance.web_server.public_ip} 'sudo tail -f /var/log/httpd/access_log'"
    instance_details = "aws ec2 describe-instances --instance-ids ${aws_instance.web_server.id}"
  }
}

# -----------------------------------------------------------------------------
# Summary Output
# -----------------------------------------------------------------------------
output "deployment_summary" {
  description = "Summary of the deployed resources"
  value = {
    instance_id      = aws_instance.web_server.id
    public_ip        = aws_instance.web_server.public_ip
    web_url          = "http://${aws_instance.web_server.public_ip}"
    ssh_command      = var.use_existing_key ? "ssh -i ${var.existing_key_path} ec2-user@${aws_instance.web_server.public_ip}" : "ssh -i ${path.module}/ssh-key-${random_id.suffix.hex}.pem ec2-user@${aws_instance.web_server.public_ip}"
    security_group   = aws_security_group.web_server_sg.id
    region           = var.aws_region
    environment      = var.environment
    instance_type    = var.instance_type
  }
}
