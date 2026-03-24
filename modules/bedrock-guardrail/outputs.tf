output "guardrail_id" {
  description = "Guardrail ID"
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_arn" {
  description = "Guardrail ARN"
  value       = aws_bedrock_guardrail.this.guardrail_arn
}

output "guardrail_version" {
  description = "Guardrail version (if created)"
  value       = var.create_version ? aws_bedrock_guardrail_version.this[0].version : "DRAFT"
}

output "guardrail_version_arn" {
  description = "Guardrail version ARN (if created)"
  value       = var.create_version ? aws_bedrock_guardrail_version.this[0].guardrail_arn : null
}

output "guardrail_name" {
  description = "Guardrail name"
  value       = aws_bedrock_guardrail.this.name
}
