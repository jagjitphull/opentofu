# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module - Production Configuration
module "vpc" {
  source = "../../modules/vpc"
  
  project_name = var.project_name
  environment  = "prod"
  
  vpc_cidr = "10.1.0.0/16"
  
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  
  subnet_configuration = {
    public = {
      enabled      = true
      count        = 3
      newbits      = 8
      netnum_start = 0
    }
    private = {
      enabled      = true
      count        = 3
      newbits      = 8
      netnum_start = 10
    }
    database = {
      enabled      = true
      count        = 3
      newbits      = 8
      netnum_start = 20
    }
  }
  
  # Multiple NAT gateways for high availability
  enable_nat_gateway  = true
  single_nat_gateway  = false
  
  # Production security groups
  security_groups = {
    alb = {
      description = "Security group for Application Load Balancer"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP from internet"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from internet"
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
    
    web = {
      description = "Security group for web tier"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
          description = "HTTP from ALB subnets"
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
      description = "Security group for application tier"
      ingress_rules = [
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
          description = "App port from web tier"
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
    
    database = {
      description = "Security group for database tier"
      ingress_rules = [
        {
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          cidr_blocks = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
          description = "MySQL from app tier"
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
    Owner       = "ProdOps"
    CostCenter  = "Production"
    Compliance  = "Required"
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

output "database_subnets" {
  value = module.vpc.database_subnet_ids
}

output "security_groups" {
  value = module.vpc.security_group_ids
}

output "db_subnet_group" {
  value = module.vpc.db_subnet_group_name
}