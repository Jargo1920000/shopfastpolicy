output "db_endpoint" {
  description = "Connection endpoint for the RDS instance."
  value       = aws_db_instance.db.endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB credentials."
  value       = aws_db_instance.db.master_user_secret[0].secret_arn
}
