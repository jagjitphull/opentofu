# =============================================================================
# Variables for Provisioners & Connections Lab
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance Configuration
# -----------------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[2-3]\\.(nano|micro|small|medium)$", var.instance_type))
    error_message = "Instance type must be a valid t2 or t3 burstable instance."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 8 and 100 GB."
  }
}

# -----------------------------------------------------------------------------
# SSH Key Configuration
# -----------------------------------------------------------------------------
variable "use_existing_key" {
  description = "Whether to use an existing SSH key pair (true) or generate a new one (false)"
  type        = bool
  default     = false
}

variable "existing_key_name" {
  description = "Name of existing AWS key pair (required if use_existing_key is true)"
  type        = string
  default     = ""
}

variable "existing_key_path" {
  description = "Path to existing private key file (required if use_existing_key is true)"
  type        = string
  default     = "~/.ssh/id_rsa"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# -----------------------------------------------------------------------------
# Provisioner Configuration
# -----------------------------------------------------------------------------
variable "enable_advanced_config" {
  description = "Enable advanced configuration provisioners"
  type        = bool
  default     = false
}

variable "provisioner_timeout" {
  description = "Timeout for provisioner connections (e.g., '5m', '10m')"
  type        = string
  default     = "5m"

  validation {
    condition     = can(regex("^[0-9]+[mh]$", var.provisioner_timeout))
    error_message = "Timeout must be in format like '5m' or '1h'."
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
