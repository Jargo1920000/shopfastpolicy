variable "env" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs for EC2 instances."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "asg_min" {
  description = "Minimum ASG instance count."
  type        = number
}

variable "asg_max" {
  description = "Maximum ASG instance count."
  type        = number
}

variable "asg_desired" {
  description = "Desired ASG instance count."
  type        = number
}
