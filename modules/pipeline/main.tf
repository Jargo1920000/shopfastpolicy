# ------------------------------------------------------------
# IAM Role for CodePipeline, CodeBuild, CodeDeploy
# ------------------------------------------------------------

resource "aws_iam_role" "pipeline" {
  name = "${var.env}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "codepipeline.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow"
        Principal = { Service = "codebuild.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
      {
        Effect    = "Allow"
        Principal = { Service = "codedeploy.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_iam_role_policy_attachment" "pipeline_policy" {
  role       = aws_iam_role.pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

resource "aws_iam_role_policy" "codestar_policy" {
  name = "${var.env}-codestar-connection-policy"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "codestar-connections:UseConnection"
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

# ------------------------------------------------------------
# S3 Bucket for Pipeline Artifacts
# ------------------------------------------------------------

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.env}-shopfast-pipeline-artifacts"
  tags   = { Environment = var.env, ManagedBy = "terraform" }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# CodeBuild Project
# ------------------------------------------------------------

resource "aws_codebuild_project" "build" {
  name         = "${var.env}-shopfast-build"
  service_role = aws_iam_role.pipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "ENV"
      value = var.env
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

# ------------------------------------------------------------
# CodeDeploy
# ------------------------------------------------------------

resource "aws_codedeploy_app" "app" {
  name             = "${var.env}-shopfast"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.env}-deployment-group"
  service_role_arn       = aws_iam_role.pipeline.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_arn]
      }

      target_group {
        name = split("/", var.blue_target_group_arn)[1]
      }

      target_group {
        name = split("/", var.green_target_group_arn)[1]
      }
    }
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}
resource "aws_iam_role_policy_attachment" "codedeploy_elb" {
  role       = aws_iam_role.pipeline.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy" "ec2_autoscaling" {
  name = "${var.env}-codedeploy-ec2-asg-policy"
  role = aws_iam_role.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:*",
          "ec2:Describe*",
          "ec2:Get*",
          "tag:GetTags",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}
# ------------------------------------------------------------
# CodeStar Connection (GitHub v2)
# ------------------------------------------------------------

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.env}-shopfast-github"
  provider_type = "GitHub"

  tags = { Environment = var.env, ManagedBy = "terraform" }
}

# IMPORTANT: After terraform apply, go to the AWS Console and manually
# authorise this connection under:
#   Developer Tools > Settings > Connections
# It stays PENDING until you do. The pipeline will not trigger until
# the connection status is AVAILABLE.

# ------------------------------------------------------------
# CodePipeline
# ------------------------------------------------------------

resource "aws_codepipeline" "pipeline" {
  name     = "${var.env}-shopfast-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.group.deployment_group_name
      }
    }
  }

  tags = { Environment = var.env, ManagedBy = "terraform" }
}
