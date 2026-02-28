variable "env" {
  description = "Deployment environment. Must be prod, staging, or dev."
  type        = string

  validation {
    condition     = contains(["prod", "staging", "dev"], var.env)
    error_message = "env must be prod, staging, or dev."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-2"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "List of availability zones to use."
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

# --- Compute ---

variable "instance_type" {
  description = "EC2 instance type for the launch template."
  type        = string
}

variable "asg_min" {
  description = "Minimum number of instances in the ASG."
  type        = number
}

variable "asg_max" {
  description = "Maximum number of instances in the ASG."
  type        = number
}

variable "asg_desired" {
  description = "Desired number of instances in the ASG."
  type        = number
}

# --- Database ---

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
}

# --- Pipeline ---

variable "github_owner" {
  description = "GitHub organisation or user that owns the repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy from."
  type        = string
}
