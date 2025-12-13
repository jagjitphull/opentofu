# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module - Development Configuration
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = "dev"

  vpc_cidr = "10.0.0.0/16"

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  subnet_configuration = {
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

  # Single NAT gateway to save costs in dev
  enable_nat_gateway = true
  single_nat_gateway = true

  # Security Groups with dynamic rules
  security_groups = {
    web = {
      description = "Security group for web servers"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from anywhere"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from anywhere"
        },
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "SSH from VPC"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }

    app = {
      description = "Security group for application servers"
      ingress_rules = [
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "App port from VPC"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }
  }

  tags = {
    Owner      = "DevTeam"
    CostCenter = "Engineering"
  }
}

# Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}

output "security_groups" {
  value = module.vpc.security_group_ids
}
