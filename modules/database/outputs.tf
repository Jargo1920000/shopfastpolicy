output "db_endpoint" {
  description = "Connection endpoint for the RDS instance."
  value       = aws_db_instance.db.endpoint
  sensitive   = true
}
