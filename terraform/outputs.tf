output "alb_dns_name" {
  description = "Public URL of the Application Load Balancer"
  value       = "http://${aws_lb.todo_alb.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL to push Docker images"
  value       = aws_ecr_repository.todo_api.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.todo_cluster.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}
