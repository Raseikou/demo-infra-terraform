output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "S3 bucket name for Terraform state"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "S3 bucket ARN"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_lock.name
  description = "DynamoDB table name for state locking"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.terraform_lock.arn
  description = "DynamoDB table ARN"
}

output "kms_key_id" {
  value       = aws_kms_key.terraform_state.id
  description = "KMS key ID for state encryption"
}

output "kms_key_arn" {
  value       = aws_kms_key.terraform_state.arn
  description = "KMS key ARN for state encryption"
}

output "cicd_user_name" {
  value       = aws_iam_user.terraform_cicd.name
  description = "IAM user name for CI/CD"
}

output "backend_state_key" {
  value       = "backend/bootstrap.tfstate"
  description = "Remote state key used by the backend stack itself"
}

output "backend_config" {
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    key            = "practice-06/terraform.tfstate"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    kms_key_id     = aws_kms_key.terraform_state.arn
  }
  description = "Backend configuration for terraform block"
}
