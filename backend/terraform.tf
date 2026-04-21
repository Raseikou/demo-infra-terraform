terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }

  # Provider requirements only.
  # The backend stack now stores its own state via backend/backend.tf using
  # the shared S3 bucket with a dedicated key.
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
