# CHANGE_ME: Replace backend settings before team usage
terraform {
  backend "s3" {
    bucket         = "CHANGE_ME_tf_state_bucket"
    key            = "CHANGE_ME/env/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "CHANGE_ME_tf_lock_table"
    encrypt        = true
  }
}
