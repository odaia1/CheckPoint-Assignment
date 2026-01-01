variable "name" {
  type        = string
  description = "ECR repository name"
}

variable "tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "MUTABLE or IMMUTABLE"
}