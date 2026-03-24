variable "aws_region" {
  description = "AWS región pre nasadenie Bedrock Guardrails"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Prostredie nasadenia (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment musí byť dev, staging alebo prod."
  }
}
