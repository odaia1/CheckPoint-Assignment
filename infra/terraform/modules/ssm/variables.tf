variable "parameter_name" {
  type        = string
  description = "SSM parameter name"
}

variable "parameter_value" {
  type        = string
  sensitive   = true
  description = "Token value"
}