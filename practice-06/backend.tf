terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }

  # S3 Backend Configuration
  # Backend infrastructure must be created first using ./backend directory
  backend "s3" {
    # These values will be populated by backend/ terraform apply
    # Update these values after running: terraform -chdir=./backend apply
    bucket         = "demo-infra-terraform-state-ACCOUNT_ID"  # Replace ACCOUNT_ID with your AWS account ID
    key            = "practice-06/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "arn:aws:kms:ap-northeast-1:ACCOUNT_ID:key/KEY_ID"  # Replace after backend creation
  }
}

provider "aws" {
  region = var.aws_region
}
