# Using our local VPC module
module "vpc" {
  source = "../../modules/aws-vpc"
  
  vpc_name           = "${var.environment}-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  
  # Public subnets for load balancers, bastion hosts
  public_subnet_cidrs = [
    "10.0.1.0/24",  # us-east-1a
    "10.0.2.0/24"   # us-east-1b
  ]
  
  # Private subnets for application servers, databases
  private_subnet_cidrs = [
    "10.0.10.0/24", # us-east-1a
    "10.0.20.0/24"  # us-east-1b
  ]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev
  
  tags = {
    Owner = "DevOps Team"
  }
}