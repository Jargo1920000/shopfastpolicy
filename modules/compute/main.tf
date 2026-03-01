# ------------------------------------------------------------
# AMI lookup - always finds the latest Amazon Linux 2023
# ------------------------------------------------------------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ------------------------------------------------------------
# IAM Role for EC2 instances
# ------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "${var.env}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_secrets" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.env}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "Allow HTTP and HTTPS inbound to the ALB."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_security_group" "ec2" {
  name        = "${var.env}-ec2-sg"
  description = "Allow traffic from the ALB only."
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
# S3 Assets Bucket
# ------------------------------------------------------------

resource "aws_s3_bucket" "assets" {
  bucket = "${var.env}-shopfast-assets"
  tags   = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_lb_target_group" "blue" {
  name     = "${var.env}-tg-blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_lb_target_group" "green" {
  name     = "${var.env}-tg-green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# ------------------------------------------------------------
# Launch Template
# ------------------------------------------------------------

resource "aws_launch_template" "app" {
  name          = "${var.env}-launch-template"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data              = base64encode(file("${path.module}/user-data.sh"))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Environment = var.env, ManagedBy = "terraform" }
  }
}

# ------------------------------------------------------------
# Auto Scaling Groups (blue / green)
# ------------------------------------------------------------

resource "aws_autoscaling_group" "blue" {
  name                = "${var.env}-asg-blue"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.blue.arn]

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }

  tag {
    key                 = "DeploymentGroup"
    value               = "blue"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "${var.env}-asg-green"
  min_size            = 0
  max_size            = var.asg_max
  desired_capacity    = 0
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.green.arn]

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }

  tag {
    key                 = "DeploymentGroup"
    value               = "green"
    propagate_at_launch = true
  }
}

# ------------------------------------------------------------
# CloudFront
# ------------------------------------------------------------

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  comment = "${var.env} shopfast CDN"

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "${var.env}-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.env}-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      cookies { forward = "all" }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}
