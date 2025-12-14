variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "provisioners-demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "create_new_key_pair" {
  description = "Create a new SSH key pair (true) or use existing (false)"
  type        = bool
  default     = true
}

variable "existing_key_pair_name" {
  description = "Name of existing key pair (only used if create_new_key_pair = false)"
  type        = string
  default     = ""
}

variable "existing_private_key_path" {
  description = "Path to existing private key file (only used if create_new_key_pair = false)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to instance"
  type        = string
  default     = "0.0.0.0/0" # ⚠️ Restrict this in production!
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
