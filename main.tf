terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "BedrockGuardrails"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Production Guardrail - kompletný príklad s všetkými funkciami
module "production_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "prod-company-guardrail"
  description = "Hlavný guardrail pre produkčného chatbota s plnou ochranou"
  environment = var.environment

  # Správy pri blokovaní
  blocked_input_messaging   = "Váš dopyt bol zablokovaný z bezpečnostných dôvodov. Prosím, preformulujte vašu otázku."
  blocked_outputs_messaging = "Odpoveď bola zablokovaná, pretože nespĺňa bezpečnostné štandardy."

  # Content Policy - ochrana pred nevhodným obsahom
  content_filters = [
    {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    },
    {
      type            = "INSULTS"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    },
    {
      type            = "SEXUAL"
      input_strength  = "MEDIUM"
      output_strength = "HIGH"
    },
    {
      type            = "VIOLENCE"
      input_strength  = "MEDIUM"
      output_strength = "HIGH"
    },
    {
      type            = "MISCONDUCT"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
  ]

  # PII ochrana - automatické maskovanie citlivých údajov
  pii_entities = [
    {
      type   = "EMAIL"
      action = "ANONYMIZE"
    },
    {
      type   = "PHONE"
      action = "ANONYMIZE"
    },
    {
      type   = "NAME"
      action = "ANONYMIZE"
    },
    {
      type   = "ADDRESS"
      action = "ANONYMIZE"
    },
    {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    },
    {
      type   = "US_SOCIAL_SECURITY_NUMBER"
      action = "BLOCK"
    },
    {
      type   = "US_BANK_ACCOUNT_NUMBER"
      action = "BLOCK"
    }
  ]

  # Blokované témy
  denied_topics = [
    {
      name       = "Investicne_Poradenstvo"
      definition = "Akékoľvek finančné rady, odporúčania na nákup akcií, kryptomien alebo investičné stratégie."
      examples = [
        "Aké akcie si mám kúpiť?",
        "Je bitcoin dobrá investícia?",
        "Poraď mi, ako investovať úspory",
        "Ktoré ETF sú najlepšie?"
      ]
    },
    {
      name       = "Zdravotne_Diagnozy"
      definition = "Poskytovanie lekárskych diagnóz alebo odporúčaní na liečbu bez lekárskeho vzdelania."
      examples = [
        "Mám bolesti hlavy, čo to môže byť?",
        "Ako sa liečí diabetes?",
        "Aký liek mám užiť na chrípku?"
      ]
    },
    {
      name       = "Pravne_Poradenstvo"
      definition = "Poskytovanie konkrétnych právnych rád alebo interpretácie zákonov."
      examples = [
        "Môžem podať žalobu na zamestnávateľa?",
        "Aké sú zákonné dôsledky?",
        "Ako mám vyplniť daňové priznanie?"
      ]
    }
  ]

  # Word filters - blokovanie konkrétnych slov
  word_filters = [
    "konkurenčná_firma_XYZ",
    "interné_heslo",
    "confidential"
  ]

  # Vytvorenie stabilnej verzie pre produkciu
  create_version      = true
  version_description = "Production v1.0 - Plná ochrana"

  tags = {
    CostCenter = "AI-Platform"
    Compliance = "GDPR"
  }
}

# Development Guardrail - miernejšie nastavenia pre vývoj
module "development_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "dev-testing-guardrail"
  description = "Vývojový guardrail s miernejšími nastaveniami pre testovanie"
  environment = var.environment

  blocked_input_messaging   = "Test: Input blocked"
  blocked_outputs_messaging = "Test: Output blocked"

  # Len základné content filters
  content_filters = [
    {
      type            = "HATE"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    },
    {
      type            = "VIOLENCE"
      input_strength  = "LOW"
      output_strength = "MEDIUM"
    }
  ]

  # Len základné PII
  pii_entities = [
    {
      type   = "EMAIL"
      action = "ANONYMIZE"
    },
    {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
  ]

  # Len jedna testovacia téma
  denied_topics = [
    {
      name       = "Test_Blocked_Topic"
      definition = "Testovacia blokovaná téma pre vývoj"
      examples   = ["testovacia veta", "debug topic"]
    }
  ]

  word_filters = []

  create_version      = false
  version_description = ""

  tags = {
    Environment = "Development"
  }
}

# Minimálny Guardrail - len PII ochrana
module "minimal_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "minimal-pii-guardrail"
  description = "Minimálny guardrail len s PII ochranou"
  environment = var.environment

  blocked_input_messaging   = "Vstup obsahuje citlivé údaje."
  blocked_outputs_messaging = "Výstup obsahuje citlivé údaje."

  content_filters = []

  pii_entities = [
    {
      type   = "EMAIL"
      action = "ANONYMIZE"
    },
    {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
  ]

  denied_topics = []
  word_filters  = []

  create_version      = true
  version_description = "Minimal PII protection v1.0"

  tags = {
    Type = "Minimal"
  }
}
