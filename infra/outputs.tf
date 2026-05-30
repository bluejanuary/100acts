output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.uploads.bucket
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.uploads.arn
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = var.aws_region
}

output "iam_access_key_id" {
  description = "IAM access key ID for app"
  value       = aws_iam_access_key.app.id
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "IAM secret access key for app"
  value       = aws_iam_access_key.app.secret
  sensitive   = true
}
