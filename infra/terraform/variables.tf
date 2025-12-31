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