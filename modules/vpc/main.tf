module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.env}-vpc"
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# ------------------------------------------------------------
# Security group for SSM VPC endpoints
# ------------------------------------------------------------

resource "aws_security_group" "endpoints" {
  name        = "${var.env}-endpoints-sg"
  description = "Allow HTTPS from within the VPC to SSM endpoints."
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

# ------------------------------------------------------------
# VPC Endpoints - required for SSM Session Manager
# in private subnets without direct internet access
# ------------------------------------------------------------

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = { Environment = var.env, ManagedBy = "terraform" }
}
