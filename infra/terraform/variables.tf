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

variable "producer_image_tag" {
  type        = string
  description = "producer image tag (version)"
}

variable "consumer_image_tag" {
  type        = string
  description = "consumer image tag (version)"
}

variable "allowed_ingress_cidr" {
  type        = string
  description = "CIDR allowed to access the ALB (use your laptop public IP/32)"
}