variable "env" {
  description = "Deployment environment."
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "List of availability zones."
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks."
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region - used to build VPC endpoint service names."
  type        = string
}
