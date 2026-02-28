output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = module.compute.alb_dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name."
  value       = module.compute.cloudfront_domain
}

output "db_endpoint" {
  description = "RDS instance endpoint."
  value       = module.database.db_endpoint
  sensitive   = true
}
