env        = "prod"
aws_region = "eu-west-2"

# Networking
vpc_cidr        = "10.0.0.0/16"
azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Compute
instance_type = "t3.medium"
asg_min       = 2
asg_max       = 6
asg_desired   = 3

# Database
db_instance_class = "db.t3.medium"
db_multi_az       = true

# Pipeline
github_owner  = "yourgithub"
github_repo   = "shopfast"
github_branch = "main"
