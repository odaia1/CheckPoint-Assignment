terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "sqs" {
  source     = "./modules/sqs"
  queue_name = "checkpoint-assignment-events"
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
}

module "ssm" {
  source           = "./modules/ssm"
  parameter_name   = "/checkpoint-assignment/token"
  parameter_value  = var.token_value
}

