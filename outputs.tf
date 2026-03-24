output "production_guardrail_id" {
  description = "ID produkčného guardrailu"
  value       = module.production_guardrail.guardrail_id
}

output "production_guardrail_arn" {
  description = "ARN produkčného guardrailu"
  value       = module.production_guardrail.guardrail_arn
}

output "production_guardrail_version" {
  description = "Verzia produkčného guardrailu"
  value       = module.production_guardrail.guardrail_version
}

output "development_guardrail_id" {
  description = "ID vývojového guardrailu"
  value       = module.development_guardrail.guardrail_id
}

output "development_guardrail_arn" {
  description = "ARN vývojového guardrailu"
  value       = module.development_guardrail.guardrail_arn
}

output "minimal_guardrail_id" {
  description = "ID minimálneho guardrailu"
  value       = module.minimal_guardrail.guardrail_id
}

output "minimal_guardrail_arn" {
  description = "ARN minimálneho guardrailu"
  value       = module.minimal_guardrail.guardrail_arn
}

output "minimal_guardrail_version" {
  description = "Verzia minimálneho guardrailu"
  value       = module.minimal_guardrail.guardrail_version
}

# Výstup pre jednoduché použitie v Python kóde
output "guardrails_summary" {
  description = "Zhrnutie všetkých guardrailov pre použitie v aplikácii"
  value = {
    production = {
      id      = module.production_guardrail.guardrail_id
      arn     = module.production_guardrail.guardrail_arn
      version = module.production_guardrail.guardrail_version
    }
    development = {
      id      = module.development_guardrail.guardrail_id
      arn     = module.development_guardrail.guardrail_arn
      version = module.development_guardrail.guardrail_version
    }
    minimal = {
      id      = module.minimal_guardrail.guardrail_id
      arn     = module.minimal_guardrail.guardrail_arn
      version = module.minimal_guardrail.guardrail_version
    }
  }
}
