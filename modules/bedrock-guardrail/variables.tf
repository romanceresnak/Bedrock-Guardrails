variable "name" {
  description = "Názov guardrailu"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Názov guardrailu môže obsahovať len alfanumerické znaky, pomlčky a podčiarkovníky."
  }
}

variable "description" {
  description = "Popis guardrailu"
  type        = string
}

variable "environment" {
  description = "Prostredie (dev, staging, prod)"
  type        = string
}

variable "blocked_input_messaging" {
  description = "Správa zobrazená používateľovi pri zablokovanom vstupe"
  type        = string
  default     = "Váš dopyt bol zablokovaný z bezpečnostných dôvodov."
}

variable "blocked_outputs_messaging" {
  description = "Správa zobrazená používateľovi pri zablokovanom výstupe"
  type        = string
  default     = "Odpoveď bola zablokovaná, pretože nespĺňa bezpečnostné štandardy."
}

variable "content_filters" {
  description = "Zoznam content filtrov (HATE, INSULTS, SEXUAL, VIOLENCE, MISCONDUCT, PROMPT_ATTACK)"
  type = list(object({
    type            = string
    input_strength  = string # NONE, LOW, MEDIUM, HIGH
    output_strength = string # NONE, LOW, MEDIUM, HIGH
  }))
  default = []

  validation {
    condition = alltrue([
      for f in var.content_filters :
      contains(["HATE", "INSULTS", "SEXUAL", "VIOLENCE", "MISCONDUCT", "PROMPT_ATTACK"], f.type)
    ])
    error_message = "Type musí byť jeden z: HATE, INSULTS, SEXUAL, VIOLENCE, MISCONDUCT, PROMPT_ATTACK."
  }

  validation {
    condition = alltrue([
      for f in var.content_filters :
      contains(["NONE", "LOW", "MEDIUM", "HIGH"], f.input_strength) &&
      contains(["NONE", "LOW", "MEDIUM", "HIGH"], f.output_strength)
    ])
    error_message = "Strength musí byť jeden z: NONE, LOW, MEDIUM, HIGH."
  }
}

variable "pii_entities" {
  description = "Zoznam PII entít na ochranu"
  type = list(object({
    type   = string
    action = string # BLOCK alebo ANONYMIZE
  }))
  default = []

  validation {
    condition = alltrue([
      for p in var.pii_entities :
      contains(["BLOCK", "ANONYMIZE"], p.action)
    ])
    error_message = "Action musí byť BLOCK alebo ANONYMIZE."
  }
}

variable "denied_topics" {
  description = "Zoznam zakázaných tém"
  type = list(object({
    name       = string
    definition = string
    examples   = list(string)
  }))
  default = []
}

variable "word_filters" {
  description = "Zoznam zakázaných slov alebo fráz"
  type        = list(string)
  default     = []
}

variable "create_version" {
  description = "Či vytvoriť verziu guardrailu (pre produkciu použite true)"
  type        = bool
  default     = false
}

variable "version_description" {
  description = "Popis verzie guardrailu"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Dodatočné tagy pre guardrail"
  type        = map(string)
  default     = {}
}
