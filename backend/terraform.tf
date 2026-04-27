terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }

  # ここでは Terraform 本体と provider の要件のみを定義します。
  # backend 自身の remote state は `backend/backend.tf` 側で管理します。
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "infrastructure"
      ManagedBy   = "Terraform"
      Component   = "Backend"
    }
  }
}
