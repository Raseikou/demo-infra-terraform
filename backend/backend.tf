terraform {
  # backend 用リソースは bootstrap 後に既に存在している前提です。
  # そのため、bucket / lock table / KMS ARN は `terraform init` 時に注入し、
  # backend スタック自身の state は専用 key に分離して保存します。
  backend "s3" {
    key     = "backend/bootstrap.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
