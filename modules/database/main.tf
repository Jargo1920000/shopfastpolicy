# ------------------------------------------------------------
# Security Group
# ------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.env}-rds-sg"
  description = "Allow PostgreSQL access from within the VPC only."
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
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
# Subnet Group
# ------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

# ------------------------------------------------------------
# RDS Instance
# ------------------------------------------------------------

resource "aws_db_instance" "db" {
  identifier        = "${var.env}-shopfast-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_encrypted = false
  multi_az          = var.multi_az

  username = "shopfast_admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot     = !var.multi_az
  backup_retention_period = var.multi_az ? 7 : 1

  tags = { Environment = var.env, ManagedBy = "terraform" }
}
