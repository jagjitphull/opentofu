variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "subnet_configuration" {
  description = "Configuration for subnet tiers"
  type = object({
    public = object({
      enabled      = bool
      count        = number
      newbits      = number
      netnum_start = number
    })
    private = object({
      enabled      = bool
      count        = number
      newbits      = number
      netnum_start = number
    })
    database = object({
      enabled      = bool
      count        = number
      newbits      = number
      netnum_start = number
    })
  })

  default = {
    public = {
      enabled      = true
      count        = 2
      newbits      = 8
      netnum_start = 0
    }
    private = {
      enabled      = true
      count        = 2
      newbits      = 8
      netnum_start = 10
    }
    database = {
      enabled      = false
      count        = 2
      newbits      = 8
      netnum_start = 20
    }
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway for all private subnets"
  type        = bool
  default     = false
}

variable "security_groups" {
  description = "Map of security group configurations"
  type = map(object({
    description = string
    ingress_rules = list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      source_security_group_id = optional(string)
      description              = string
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  }))
  default = {}
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
