variable "env" {
  description = "Deployment environment."
  type        = string
}

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

variable "blue_target_group_arn" {
  description = "ARN of the blue ALB target group."
  type        = string
}

variable "green_target_group_arn" {
  description = "ARN of the green ALB target group."
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener used by CodeDeploy to shift traffic."
  type        = string
}

variable "blue_asg_name" {
  description = "Name of the blue Auto Scaling Group for CodeDeploy."
  type        = string
}
