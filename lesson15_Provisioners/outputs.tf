output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = var.create_new_key_pair ? "ssh -i ${path.module}/provisioner-key.pem ec2-user@${aws_instance.web.public_ip}" : "ssh -i ${var.existing_private_key_path} ec2-user@${aws_instance.web.public_ip}"
}

output "key_pair_name" {
  description = "Name of the SSH key pair used"
  value       = var.create_new_key_pair ? aws_key_pair.provisioner[0].key_name : var.existing_key_pair_name
}

output "private_key_path" {
  description = "Path to private key file"
  value       = var.create_new_key_pair ? "${path.module}/provisioner-key.pem" : var.existing_private_key_path
  sensitive   = true
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    region            = data.aws_region.current.name
    availability_zone = aws_instance.web.availability_zone
    ami_id            = aws_instance.web.ami
    instance_type     = aws_instance.web.instance_type
    vpc_id            = aws_vpc.main.id
    subnet_id         = aws_subnet.public.id
  }
}
