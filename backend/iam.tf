# GitHub Actions から Terraform を実行するための IAM ユーザー
resource "aws_iam_user" "terraform_cicd" {
  name = "${var.project_name}-terraform-cicd"

  tags = {
    Purpose = "GitHub Actions CI/CD"
  }
}

# state バケットへアクセスするための権限
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

# state lock テーブルを操作するための権限
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

# KMS 暗号化に必要な最小限の権限
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

# S3 用ポリシーをユーザーへ付与
resource "aws_iam_user_policy" "terraform_s3_policy" {
  name   = "${var.project_name}-terraform-s3-policy"
  user   = aws_iam_user.terraform_cicd.name
  policy = data.aws_iam_policy_document.terraform_s3_policy.json
}

# DynamoDB 用ポリシーをユーザーへ付与
resource "aws_iam_user_policy" "terraform_dynamodb_policy" {
  name   = "${var.project_name}-terraform-dynamodb-policy"
  user   = aws_iam_user.terraform_cicd.name
  policy = data.aws_iam_policy_document.terraform_dynamodb_policy.json
}

# KMS 用ポリシーをユーザーへ付与
resource "aws_iam_user_policy" "terraform_kms_policy" {
  name   = "${var.project_name}-terraform-kms-policy"
  user   = aws_iam_user.terraform_cicd.name
  policy = data.aws_iam_policy_document.terraform_kms_policy.json
}

# Access Key はあえて Terraform 管理の対象外にしています。
# secret access key は作成時に一度しか表示されないため、
# bootstrap 失敗後の state 復旧を難しくしやすいからです。
# そのため、Terraform では IAM ユーザーと権限だけを管理し、
# 実際の認証情報は GitHub Secrets に保存します。
