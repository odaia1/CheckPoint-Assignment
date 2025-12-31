terraform {
  backend "s3" {
    bucket         = "odaia-terraform-bootstrap"
    key            = "checkpoint-assignment/infra/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "odaia-terraform-bootstrap-lock"
    encrypt        = true
  }
}