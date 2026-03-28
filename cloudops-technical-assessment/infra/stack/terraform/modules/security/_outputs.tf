output "ecs_task_security_group_id" {
  description = "ECS Task Security Group ID"
  value       = aws_security_group.ecs_tasks.id
}
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}
