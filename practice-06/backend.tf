terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }

  # S3 Backend Configuration
  # Backend infrastructure must be created first using ./backend directory.
  # The actual bucket / lock table / KMS key values are injected at
  # `terraform init` time so account-specific settings do not need to live
  # in the repository.
  backend "s3" {
    key     = "practice-06/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}
