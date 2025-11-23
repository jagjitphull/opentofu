output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_url" {
  description = "URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "database_endpoint" {
  description = "Database connection endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "current_capacity" {
  description = "Current number of instances"
  value       = aws_autoscaling_group.app.desired_capacity
}