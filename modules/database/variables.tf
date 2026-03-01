variable "env" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS. Set to true for prod."
  type        = bool
}

variable "db_password" {
  description = "Master password for the RDS instance."
  type        = string
  sensitive   = true
}
