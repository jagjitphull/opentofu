output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    for subnet in local.public_subnets :
    aws_subnet.main[subnet.name].id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    for subnet in local.private_subnets :
    aws_subnet.main[subnet.name].id
  ]
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value = [
    for subnet in local.database_subnets :
    aws_subnet.main[subnet.name].id
  ]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value = [
    for subnet in local.public_subnets :
    subnet.cidr_block
  ]
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value = [
    for subnet in local.private_subnets :
    subnet.cidr_block
  ]
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of database subnets"
  value = [
    for subnet in local.database_subnets :
    subnet.cidr_block
  ]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value = [
    for nat in aws_nat_gateway.main :
    nat.id
  ]
}

output "security_group_ids" {
  description = "Map of security group names to IDs"
  value = {
    for name, sg in aws_security_group.main :
    name => sg.id
  }
}

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = try(aws_db_subnet_group.main[0].name, null)
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.availability_zones
}
