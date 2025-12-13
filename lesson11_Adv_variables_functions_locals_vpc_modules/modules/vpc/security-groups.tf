# Security Groups with dynamic rules
resource "aws_security_group" "main" {
  for_each = var.security_groups

  name        = "${local.name_prefix}-${each.key}-sg"
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-sg"
    }
  )
}

# Dynamic Ingress Rules
resource "aws_security_group_rule" "ingress" {
  for_each = merge([
    for sg_name, sg_config in var.security_groups : {
      for idx, rule in sg_config.ingress_rules :
      "${sg_name}-ingress-${idx}" => merge(rule, {
        security_group_id = aws_security_group.main[sg_name].id
      })
    }
  ]...)

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = each.value.security_group_id

  # Use either CIDR blocks or source security group
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)

  description = each.value.description
}

# Dynamic Egress Rules
resource "aws_security_group_rule" "egress" {
  for_each = merge([
    for sg_name, sg_config in var.security_groups : {
      for idx, rule in sg_config.egress_rules :
      "${sg_name}-egress-${idx}" => merge(rule, {
        security_group_id = aws_security_group.main[sg_name].id
      })
    }
  ]...)

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = each.value.security_group_id
  description       = each.value.description
}
