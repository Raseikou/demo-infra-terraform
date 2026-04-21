terraform {
  # Backend bootstrap resources already exist at this point, so we keep the
  # bucket / lock table / KMS ARN values injected at init time and store the
  # backend stack in its own dedicated key.
  backend "s3" {
    key     = "backend/bootstrap.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
