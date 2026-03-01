terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Bucket and lock table are created by running bootstrap/ first.
    # Supply the key at init time so each environment gets its own state file:
    #
    #   prod:    terraform init -backend-config="key=shopfast/prod/terraform.tfstate"
    #   staging: terraform init -backend-config="key=shopfast/staging/terraform.tfstate" -reconfigure
    #   dev:     terraform init -backend-config="key=shopfast/dev/terraform.tfstate"     -reconfigure
    bucket         = "shopfast-tfstate"
    region         = "eu-west-2"
    dynamodb_table = "shopfast-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  env             = var.env
  cidr            = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  aws_region      = var.aws_region
}

module "compute" {
  source = "./modules/compute"

  env             = var.env
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  instance_type   = var.instance_type
  asg_min         = var.asg_min
  asg_max         = var.asg_max
  asg_desired     = var.asg_desired
}

module "database" {
  source = "./modules/database"

  env            = var.env
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnets
  instance_class = var.db_instance_class
  multi_az       = var.db_multi_az
  db_password    = var.db_password
}

module "pipeline" {
  source = "./modules/pipeline"

  env                    = var.env
  github_owner           = var.github_owner
  github_repo            = var.github_repo
  github_branch          = var.github_branch
  blue_target_group_arn  = module.compute.blue_target_group_arn
  green_target_group_arn = module.compute.green_target_group_arn
  alb_listener_arn       = module.compute.alb_listener_arn
}
