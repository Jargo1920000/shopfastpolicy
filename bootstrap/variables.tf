variable "aws_region" {
  description = "AWS region to create state resources in."
  type        = string
  default     = "eu-west-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state. Must be globally unique."
  type        = string
  default     = "shopfast-tfstate"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  type        = string
  default     = "shopfast-tfstate-lock"
}
