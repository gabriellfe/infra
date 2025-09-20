output "admin_password" {
  value     = random_string.admin_password.result
  sensitive = true
}

output "rabbit_password" {
  value     = random_string.rabbit_password.result
  sensitive = true
}

output "secret_cookie" {
  value     = random_string.secret_cookie.result
  sensitive = true
}

output "backup_bucket_name" {
  description = "Name of the S3 bucket used for RabbitMQ definitions backup"
  value       = var.rabbitmq_backup_bucket
}

output "backup_bucket_arn" {
  description = "ARN of the S3 bucket used for RabbitMQ definitions backup"
  value       = var.create_backup_bucket ? aws_s3_bucket.rabbitmq_backup[0].arn : null
}