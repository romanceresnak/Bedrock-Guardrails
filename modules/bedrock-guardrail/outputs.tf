output "guardrail_id" {
  description = "ID guardrailu"
  value       = aws_bedrock_guardrail.this.guardrail_id
}

output "guardrail_arn" {
  description = "ARN guardrailu"
  value       = aws_bedrock_guardrail.this.guardrail_arn
}

output "guardrail_version" {
  description = "Verzia guardrailu (ak bola vytvorená)"
  value       = var.create_version ? aws_bedrock_guardrail_version.this[0].version : "DRAFT"
}

output "guardrail_version_arn" {
  description = "ARN verzie guardrailu (ak bola vytvorená)"
  value       = var.create_version ? aws_bedrock_guardrail_version.this[0].guardrail_arn : null
}

output "guardrail_name" {
  description = "Názov guardrailu"
  value       = aws_bedrock_guardrail.this.name
}

output "guardrail_created_at" {
  description = "Čas vytvorenia guardrailu"
  value       = aws_bedrock_guardrail.this.created_at
}

output "guardrail_updated_at" {
  description = "Čas poslednej aktualizácie guardrailu"
  value       = aws_bedrock_guardrail.this.updated_at
}
