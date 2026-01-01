variable "aws_region" {
  type        = string
  description = "AWS region for this environment"
}

variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name for the app bucket"
}

variable "token_value" {
  type        = string
  sensitive   = true
  description = "Shared API token"
}

variable "producer_image" {
  type        = string
  description = "Full ECR image URI for producer (including tag)"
}

variable "consumer_image" {
  type        = string
  description = "Full ECR image URI for consumer (including tag)"
}

variable "allowed_ingress_cidr" {
  type        = string
  description = "CIDR allowed to access the ALB (use your laptop public IP/32)"
}