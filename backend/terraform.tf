terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }

  # Backend 配置本身使用本地 state
  # 只有一次性体系设置
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
