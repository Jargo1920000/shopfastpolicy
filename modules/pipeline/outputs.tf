output "pipeline_name" {
  description = "Name of the CodePipeline."
  value       = aws_codepipeline.pipeline.name
}

output "artifacts_bucket" {
  description = "Name of the S3 bucket storing pipeline artifacts."
  value       = aws_s3_bucket.artifacts.bucket
}
