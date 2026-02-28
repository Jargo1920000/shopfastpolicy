env        = "dev"
aws_region = "eu-west-2"

# Networking
vpc_cidr        = "10.2.0.0/16"
azs             = ["eu-west-2a"]
private_subnets = ["10.2.1.0/24"]
public_subnets  = ["10.2.101.0/24"]

# Compute
instance_type = "t3.micro"
asg_min       = 1
asg_max       = 2
asg_desired   = 1

# Database
db_instance_class = "db.t3.micro"
db_multi_az       = false

# Pipeline
github_owner  = "yourgithub"
github_repo   = "shopfast"
github_branch = "dev"
