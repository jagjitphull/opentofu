# Public Route Table
resource "aws_route_table" "public" {
  count = var.subnet_configuration.public.enabled ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
      Tier = "Public"
    }
  )
}

# Public Route to Internet Gateway
resource "aws_route" "public_internet" {
  count = var.subnet_configuration.public.enabled ? 1 : 0
  
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = {
    for subnet in local.public_subnets :
    subnet.name => subnet
  }
  
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Tables (one per AZ if multiple NAT gateways)
resource "aws_route_table" "private" {
  for_each = var.subnet_configuration.private.enabled ? {
    for i in range(var.single_nat_gateway ? 1 : length(local.private_subnets)) :
    "private-${i + 1}" => i
  } : {}
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-rt-${each.value + 1}"
      Tier = "Private"
    }
  )
}

# Private Routes to NAT Gateway
resource "aws_route" "private_nat" {
  for_each = var.subnet_configuration.private.enabled && var.enable_nat_gateway ? {
    for i in range(var.single_nat_gateway ? 1 : length(local.private_subnets)) :
    "private-${i + 1}" => i
  } : {}
  
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[
    var.single_nat_gateway ? "nat-1" : "nat-${each.value + 1}"
  ].id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  for_each = {
    for subnet in local.private_subnets :
    subnet.name => subnet
  }
  
  subnet_id = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.private[
    var.single_nat_gateway ? "private-1" : "private-${each.value.index + 1}"
  ].id
}

# Database Route Tables
resource "aws_route_table" "database" {
  for_each = var.subnet_configuration.database.enabled ? {
    for i in range(var.single_nat_gateway ? 1 : length(local.database_subnets)) :
    "database-${i + 1}" => i
  } : {}
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-rt-${each.value + 1}"
      Tier = "Database"
    }
  )
}

# Database Routes to NAT Gateway (conditional)
resource "aws_route" "database_nat" {
  for_each = var.subnet_configuration.database.enabled && var.enable_nat_gateway ? {
    for i in range(var.single_nat_gateway ? 1 : length(local.database_subnets)) :
    "database-${i + 1}" => i
  } : {}
  
  route_table_id         = aws_route_table.database[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[
    var.single_nat_gateway ? "nat-1" : "nat-${each.value + 1}"
  ].id
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  for_each = {
    for subnet in local.database_subnets :
    subnet.name => subnet
  }
  
  subnet_id = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.database[
    var.single_nat_gateway ? "database-1" : "database-${each.value.index + 1}"
  ].id
}