# IAM User for CI/CD (GitHub Actions)
resource "aws_iam_user" "terraform_cicd" {
  name = "${var.project_name}-terraform-cicd"

  tags = {
    Purpose = "GitHub Actions CI/CD"
  }
}

# IAM Policy - S3 state bucket access
data "aws_iam_policy_document" "terraform_s3_policy" {
  statement {
    sid    = "S3StateBucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn
    ]
  }

  statement {
    sid    = "S3StateFileAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]
  }
}

# IAM Policy - DynamoDB state locking
data "aws_iam_policy_document" "terraform_dynamodb_policy" {
  statement {
    sid    = "DynamoDBStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem"
    ]
    resources = [
      aws_dynamodb_table.terraform_lock.arn
    ]
  }
}

# IAM Policy - KMS access for encryption
data "aws_iam_policy_document" "terraform_kms_policy" {
  statement {
    sid    = "KMSEncryptionAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.terraform_state.arn
    ]
  }
}

# Attach S3 policy
resource "aws_iam_user_policy" "terraform_s3_policy" {
  name   = "${var.project_name}-terraform-s3-policy"
  user   = aws_iam_user.terraform_cicd.name
  policy = data.aws_iam_policy_document.terraform_s3_policy.json
}

# Attach DynamoDB policy
resource "aws_iam_user_policy" "terraform_dynamodb_policy" {
  name   = "${var.project_name}-terraform-dynamodb-policy"
  user   = aws_iam_user.terraform_cicd.name
  policy = data.aws_iam_policy_document.terraform_dynamodb_policy.json
}

# Attach KMS policy
resource "aws_iam_user_policy" "terraform_kms_policy" {
  name   = "${var.project_name}-terraform-kms-policy"
  user   = aws_iam_user.terraform_cicd.name
  policy = data.aws_iam_policy_document.terraform_kms_policy.json
}

# Create access key for CI/CD
resource "aws_iam_access_key" "terraform_cicd" {
  user = aws_iam_user.terraform_cicd.name

  depends_on = [
    aws_iam_user_policy.terraform_s3_policy,
    aws_iam_user_policy.terraform_dynamodb_policy,
    aws_iam_user_policy.terraform_kms_policy
  ]
}
