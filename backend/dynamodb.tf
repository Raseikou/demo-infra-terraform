# DynamoDB Table for Terraform state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name           = var.state_lock_table_name
  hash_key       = "LockID"
  billing_mode   = var.state_lock_capacity == 0 ? "PAY_PER_REQUEST" : "PROVISIONED"
  read_capacity  = var.state_lock_capacity == 0 ? null : 5
  write_capacity = var.state_lock_capacity == 0 ? null : 5

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  tags = {
    Name = "${var.project_name}-terraform-lock"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# TTL for old lock records (optional cleanup)
resource "aws_dynamodb_ttl" "terraform_lock" {
  attribute_name = "ExpirationTime"
  table_name     = aws_dynamodb_table.terraform_lock.name

  enabled = true
}
