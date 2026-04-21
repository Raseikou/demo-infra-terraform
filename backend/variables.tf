variable "aws_region" {
  type        = string
  description = "AWS region for backend infrastructure"
  default     = "ap-northeast-1"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "demo-infra"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
}

variable "enable_state_locking" {
  type        = bool
  description = "Enable DynamoDB state locking"
  default     = true
}

variable "state_lock_table_name" {
  type        = string
  description = "DynamoDB table name for state locking"
  default     = "terraform-state-lock"
}

variable "state_lock_capacity" {
  type        = number
  description = "DynamoDB on-demand billing (0) or provisioned (1-40000)"
  default     = 0
}

variable "enable_versioning" {
  type        = bool
  description = "Enable S3 bucket versioning"
  default     = true
}

variable "enable_mfa_delete" {
  type        = bool
  description = "Require MFA for deletion (requires bucket owner account verification)"
  default     = false
}

variable "state_retention_days" {
  type        = number
  description = "Days to retain non-current state file versions"
  default     = 90
}

variable "enable_kms_encryption" {
  type        = bool
  description = "Use KMS for S3 encryption instead of SSE-S3"
  default     = true
}

variable "enable_replication" {
  type        = bool
  description = "Enable S3 cross-region replication for disaster recovery"
  default     = false
}

variable "replication_region" {
  type        = string
  description = "Region for cross-region replication"
  default     = "us-west-2"
}
