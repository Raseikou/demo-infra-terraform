aws_region   = "ap-northeast-1"
project_name = "demo-infra"
environment  = "production"

enable_state_locking  = true
state_lock_table_name = "terraform-state-lock"
state_lock_capacity   = 0 # PAY_PER_REQUEST

enable_versioning    = true
enable_mfa_delete    = false
state_retention_days = 90

enable_kms_encryption = true
enable_replication    = false
