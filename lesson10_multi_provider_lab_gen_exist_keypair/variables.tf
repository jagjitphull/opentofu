variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = true
}

variable "existing_key_pair_name" {
  description = "Name of existing key pair (if create_key_pair is false)"
  type        = string
  default     = ""
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH"
  type        = string
  default     = "0.0.0.0/0" # Restrict this in production!
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30
}
