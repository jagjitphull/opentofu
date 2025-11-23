# Local values - computed values used multiple times
# Locals are like variables but computed, not user-input

locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    CreatedAt   = timestamp()
  }

  # Naming prefix for consistency
  name_prefix = "${var.project_name}-${var.environment}"

  # Availability zones (dynamic based on region)
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Subnet CIDR calculation
  public_subnet_cidrs = [
    for i in range(var.az_count) :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]

  private_subnet_cidrs = [
    for i in range(var.az_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  database_subnet_cidrs = [
    for i in range(var.az_count) :
    cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]
}