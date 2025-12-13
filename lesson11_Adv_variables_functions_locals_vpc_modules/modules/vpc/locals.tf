locals {
  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Common tags for all resources
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Module      = "vpc"
    },
    var.tags
  )

  # Calculate number of AZs to use
  az_count = min(
    length(var.availability_zones),
    max(
      var.subnet_configuration.public.enabled ? var.subnet_configuration.public.count : 0,
      var.subnet_configuration.private.enabled ? var.subnet_configuration.private.count : 0,
      var.subnet_configuration.database.enabled ? var.subnet_configuration.database.count : 0
    )
  )

  # Cycle through AZs for subnet distribution
  availability_zones = slice(var.availability_zones, 0, local.az_count)

  # Generate public subnet configurations
  public_subnets = var.subnet_configuration.public.enabled ? [
    for i in range(var.subnet_configuration.public.count) : {
      name = "${local.name_prefix}-public-${i + 1}"
      cidr_block = cidrsubnet(
        var.vpc_cidr,
        var.subnet_configuration.public.newbits,
        var.subnet_configuration.public.netnum_start + i
      )
      availability_zone = element(local.availability_zones, i)
      tier              = "public"
      index             = i
    }
  ] : []

  # Generate private subnet configurations
  private_subnets = var.subnet_configuration.private.enabled ? [
    for i in range(var.subnet_configuration.private.count) : {
      name = "${local.name_prefix}-private-${i + 1}"
      cidr_block = cidrsubnet(
        var.vpc_cidr,
        var.subnet_configuration.private.newbits,
        var.subnet_configuration.private.netnum_start + i
      )
      availability_zone = element(local.availability_zones, i)
      tier              = "private"
      index             = i
    }
  ] : []

  # Generate database subnet configurations
  database_subnets = var.subnet_configuration.database.enabled ? [
    for i in range(var.subnet_configuration.database.count) : {
      name = "${local.name_prefix}-database-${i + 1}"
      cidr_block = cidrsubnet(
        var.vpc_cidr,
        var.subnet_configuration.database.newbits,
        var.subnet_configuration.database.netnum_start + i
      )
      availability_zone = element(local.availability_zones, i)
      tier              = "database"
      index             = i
    }
  ] : []

  # Combine all subnets
  all_subnets = concat(
    local.public_subnets,
    local.private_subnets,
    local.database_subnets
  )

  # Create map of subnets for for_each
  subnets_map = {
    for subnet in local.all_subnets :
    subnet.name => subnet
  }

  # Determine NAT gateway count
  nat_gateway_count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : length(local.public_subnets)
  ) : 0

  # Create NAT gateway configurations
  nat_gateways = {
    for i in range(local.nat_gateway_count) :
    "nat-${i + 1}" => {
      subnet_id = aws_subnet.main[local.public_subnets[i].name].id
      name      = "${local.name_prefix}-nat-${i + 1}"
    }
  }
}
