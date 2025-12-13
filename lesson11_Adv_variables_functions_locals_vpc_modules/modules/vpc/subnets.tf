# Subnets - dynamically created from local values
resource "aws_subnet" "main" {
  for_each = local.subnets_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.tier == "public" ? true : false

  tags = merge(
    local.common_tags,
    {
      Name = each.value.name
      Tier = title(each.value.tier)
      AZ   = each.value.availability_zone
    }
  )
}

# Database Subnet Group (conditional)
resource "aws_db_subnet_group" "main" {
  count = var.subnet_configuration.database.enabled ? 1 : 0

  name = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [
    for subnet in local.database_subnets :
    aws_subnet.main[subnet.name].id
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-subnet-group"
    }
  )
}
