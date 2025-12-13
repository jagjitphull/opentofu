# AWS VPC Module

A production-ready OpenTofu module for creating AWS VPC with public and private subnets.

## Features

- VPC with customizable CIDR block
- Public subnets with Internet Gateway
- Private subnets with optional NAT Gateway
- Multi-AZ deployment
- Cost optimization options (single NAT gateway)
- Comprehensive tagging support

## Usage
```hcl
module "vpc" {
  source = "./modules/aws-vpc"
  
  vpc_name           = "my-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway  = true
  single_nat_gateway  = true
  
  tags = {
    Environment = "dev"
    ManagedBy   = "OpenTofu"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_name | Name of the VPC | string | n/a | yes |
| vpc_cidr | CIDR block for the VPC | string | n/a | yes |
| availability_zones | List of AZs for subnet placement | list(string) | n/a | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | list(string) | [] | no |
| private_subnet_cidrs | CIDR blocks for private subnets | list(string) | [] | no |
| enable_nat_gateway | Enable NAT Gateway | bool | false | no |
| single_nat_gateway | Use single NAT Gateway | bool | true | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |

## Version

Current version: 1.0.0