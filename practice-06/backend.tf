terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }

  # S3 backend の固定設定のみをここに置きます。
  # 実際の bucket / lock table / KMS ARN は CI 側の `terraform init`
  # で注入するため、アカウント依存の値をリポジトリに固定しません。
  backend "s3" {
    key     = "practice-06/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
