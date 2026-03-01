env        = "staging"
aws_region = "eu-west-2"

# Networking
vpc_cidr        = "10.1.0.0/16"
azs             = ["eu-west-2a", "eu-west-2b"]
private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]

# Compute
instance_type = "t3.micro"
asg_min       = 1
asg_max       = 3
asg_desired   = 2

# Database
db_instance_class = "db.t3.micro"
db_multi_az       = false

# Pipeline
github_owner  = "Jargo1920000"
github_repo   = "shopfastpolicy"
github_branch = "staging"