output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.alb.dns_name
}

output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "alb_sg_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "ec2_sg_id" {
  description = "ID of the EC2 security group."
  value       = aws_security_group.ec2.id
}

output "blue_target_group_arn" {
  description = "ARN of the blue target group."
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  description = "ARN of the green target group."
  value       = aws_lb_target_group.green.arn
}
