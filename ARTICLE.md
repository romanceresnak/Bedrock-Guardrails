# AWS Bedrock Guardrails: Komplexné Terraform Riešenie s CI/CD

## Úvod

AWS Bedrock Guardrails predstavujú kľúčovú bezpečnostnú vrstvu pre AI aplikácie postavené na foundation modeloch. Tento článok popisuje komplexné produkčné riešenie, ktoré kombinuje Infrastructure as Code (Terraform), automatizované CI/CD pipeline (GitHub Actions), a best practices pre nasadenie guardrailov v reálnom prostredí.

## 1. Čo sú AWS Bedrock Guardrails?

### Základný koncept

AWS Bedrock Guardrails sú bezpečnostná vrstva, ktorá kontroluje a filtruje vstupné aj výstupné dáta pri komunikácii s foundation modelmi (ako Claude, Llama, atď.). Fungujú ako "strážca", ktorý zabezpečuje, že:

- **Vstupy od používateľov** neobsahujú nevhodný obsah alebo citlivé údaje
- **Výstupy z AI modelov** spĺňajú bezpečnostné a etické štandardy
- **PII (Personal Identifiable Information)** údaje sú chránené
- **Zakázané témy** sú automaticky blokované

### Architektúra Guardrailov

```
┌─────────────┐
│   Používateľ │
└──────┬──────┘
       │ Prompt
       ▼
┌──────────────────────────────┐
│   Bedrock Guardrail          │
│                              │
│  ┌────────────────────────┐ │
│  │ Input Assessment       │ │
│  │ - Content filters      │ │
│  │ - PII detection        │ │
│  │ - Topic blocking       │ │
│  │ - Word filters         │ │
│  └────────────────────────┘ │
└──────────┬───────────────────┘
           │ Filtered prompt
           ▼
┌──────────────────────────────┐
│   Foundation Model           │
│   (Claude, Llama, etc.)      │
└──────────┬───────────────────┘
           │ Response
           ▼
┌──────────────────────────────┐
│   Bedrock Guardrail          │
│                              │
│  ┌────────────────────────┐ │
│  │ Output Assessment      │ │
│  │ - Content filters      │ │
│  │ - PII detection        │ │
│  │ - Harmful content      │ │
│  └────────────────────────┘ │
└──────────┬───────────────────┘
           │ Safe response
           ▼
┌──────────────────────────────┐
│   Aplikácia                  │
└──────────────────────────────┘
```

### Typy ochran

#### 1. Content Filters (Obsahové filtre)

Detekujú a blokujú nevhodný obsah na základe kategórií:

- **HATE**: Nenávistné prejavy, diskriminácia
- **INSULTS**: Urážky, vulgárny jazyk
- **SEXUAL**: Sexuálny obsah
- **VIOLENCE**: Násilie, hrozby
- **MISCONDUCT**: Nevhodné správanie
- **PROMPT_ATTACK**: Prompt injection útoky

Každý filter má nastaviteľnú silu:
- `NONE`: Vypnuté
- `LOW`: Blokuje len extrémne prípady
- `MEDIUM`: Vyvážená ochrana
- `HIGH`: Maximálna ochrana (odporúčané pre produkciu)

#### 2. PII Entities (Ochrana osobných údajov)

Detekuje a spracováva citlivé osobné údaje:

**Top 15 PII entít:**
- `EMAIL`: Emailové adresy
- `PHONE`: Telefónne čísla
- `NAME`: Mená osôb
- `ADDRESS`: Adresy
- `CREDIT_DEBIT_CARD_NUMBER`: Čísla kreditných kariet
- `CREDIT_DEBIT_CARD_CVV`: CVV kódy
- `US_SOCIAL_SECURITY_NUMBER`: SSN čísla
- `US_BANK_ACCOUNT_NUMBER`: Bankové účty
- `IP_ADDRESS`: IP adresy
- `USERNAME`: Používateľské mená
- `PASSWORD`: Heslá
- `AWS_ACCESS_KEY`: AWS access keys
- `AWS_SECRET_KEY`: AWS secret keys
- `URL`: URL adresy
- `AGE`: Vek

**Akcie:**
- `ANONYMIZE`: Nahradí údaj placeholder (napr. `[EMAIL]`, `[PHONE]`)
- `BLOCK`: Úplne zablokuje request

#### 3. Topic Policy (Blokované témy)

Detekuje a blokuje špecifické témy konverzácie:

**Príklad konfigurácie:**
```hcl
denied_topics = [
  {
    name       = "Investment_Advice"
    definition = "Any financial advice, stock recommendations, or investment strategies"
    examples   = [
      "What stocks should I buy?",
      "Is Bitcoin a good investment?",
      "How should I invest my savings?"
    ]
  }
]
```

Model sa učí rozpoznať témy na základe:
- **Definition**: Textový popis témy
- **Examples**: Príklady otázok/promptov
- **Embeddings**: AI model analyzuje sémantický význam

#### 4. Word Filters (Filtrovanie slov)

Blokovanie konkrétnych slov alebo fráz:

```hcl
word_filters = [
  "competitor_company_XYZ",
  "internal_password",
  "confidential",
  "do_not_share"
]
```

Užitočné pre:
- Blokovanie konkurencie
- Ochrana interných termínov
- Compliance požiadavky

---

## 2. Architektúra Terraform Riešenia

### High-Level Architektúra

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Repository                    │
│                                                         │
│  ┌───────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │  main.tf      │  │  variables   │  │  modules/   │ │
│  │  outputs.tf   │  │  .tfvars     │  │  outputs    │ │
│  └───────────────┘  └──────────────┘  └─────────────┘ │
└────────────┬────────────────────────────────────────────┘
             │ Push to main
             ▼
┌─────────────────────────────────────────────────────────┐
│              GitHub Actions (CI/CD)                     │
│                                                         │
│  1. Validate ──▶ 2. Test ──▶ 3. Plan ──▶ 4. Apply    │
└────────────┬────────────────────────────────────────────┘
             │ OIDC Authentication
             ▼
┌─────────────────────────────────────────────────────────┐
│                    AWS Account                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           IAM Role (OIDC)                        │  │
│  │  - Bedrock permissions                           │  │
│  │  - S3 backend access                             │  │
│  │  - DynamoDB lock access                          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │ S3 Bucket    │  │ DynamoDB     │  │  Bedrock    │  │
│  │ (Tf State)   │  │ (Tf Lock)    │  │ Guardrails  │  │
│  └──────────────┘  └──────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Komponenty riešenia

#### 1. Terraform Backend (S3 + DynamoDB)

**Prečo je potrebný?**

V CI/CD prostredí potrebujeme perzistentný state, ktorý prežije medzi jednotlivými workflow runs. Bez backendu by každý GitHub Actions run začínal s čistým state-om a pokúsil by sa vytvoriť guardraily znova.

**S3 Bucket:**
```hcl
backend "s3" {
  bucket         = "bedrock-guardrails-terraform-state"
  key            = "terraform.tfstate"
  region         = "eu-west-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

**Vlastnosti:**
- **Versioning enabled**: História zmien state súboru
- **Encryption at rest**: AES-256 šifrovanie
- **Access control**: Len IAM role má prístup

**DynamoDB Table:**
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

**Účel:**
- Zamedzuje súbežným Terraform run-om
- Zabezpečuje konzistenciu state
- Pay-per-request model (žiadne fixné náklady)

#### 2. Terraform Module (bedrock-guardrail)

**Štruktúra modulu:**

```
modules/bedrock-guardrail/
├── main.tf           # Hlavná logika modulu
├── variables.tf      # Input premenné
└── outputs.tf        # Output hodnoty
```

**main.tf - Kľúčové bloky:**

```hcl
resource "aws_bedrock_guardrail" "this" {
  name        = var.name
  description = var.description

  blocked_input_messaging   = var.blocked_input_messaging
  blocked_outputs_messaging = var.blocked_outputs_messaging

  # Dynamic content policy
  dynamic "content_policy_config" {
    for_each = length(var.content_filters) > 0 ? [1] : []

    content {
      dynamic "filters_config" {
        for_each = var.content_filters

        content {
          type            = filters_config.value.type
          input_strength  = filters_config.value.input_strength
          output_strength = filters_config.value.output_strength
        }
      }
    }
  }

  # Dynamic PII policy
  dynamic "sensitive_information_policy_config" {
    for_each = length(var.pii_entities) > 0 ? [1] : []

    content {
      dynamic "pii_entities_config" {
        for_each = var.pii_entities

        content {
          type   = pii_entities_config.value.type
          action = pii_entities_config.value.action
        }
      }
    }
  }

  # Dynamic topic policy
  dynamic "topic_policy_config" {
    for_each = length(var.denied_topics) > 0 ? [1] : []

    content {
      dynamic "topics_config" {
        for_each = var.denied_topics

        content {
          name       = topics_config.value.name
          definition = topics_config.value.definition
          examples   = topics_config.value.examples
          type       = "DENY"
        }
      }
    }
  }

  # Dynamic word policy
  dynamic "word_policy_config" {
    for_each = length(var.word_filters) > 0 ? [1] : []

    content {
      dynamic "words_config" {
        for_each = var.word_filters

        content {
          text = words_config.value
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
    }
  )
}

# Optional versioning
resource "aws_bedrock_guardrail_version" "this" {
  count = var.create_version ? 1 : 0

  guardrail_arn = aws_bedrock_guardrail.this.guardrail_arn
  description   = var.version_description
}
```

**Prečo dynamic bloky?**

Dynamic bloky umožňujú:
- Vytvorenie guardrail-u s ľubovoľným počtom filtrov
- Podmienené vytvorenie sekcií (napr. topic_policy len ak sú definované témy)
- Reusability modulu pre rôzne use cases

#### 3. Tri predkonfigurované guardraily

**Production Guardrail:**
```hcl
module "production_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "prod-company-guardrail-v2"
  description = "Production guardrail with full protection"

  content_filters = [
    { type = "HATE",       input_strength = "HIGH", output_strength = "HIGH" },
    { type = "INSULTS",    input_strength = "HIGH", output_strength = "HIGH" },
    { type = "SEXUAL",     input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "VIOLENCE",   input_strength = "MEDIUM", output_strength = "HIGH" },
    { type = "MISCONDUCT", input_strength = "MEDIUM", output_strength = "MEDIUM" }
  ]

  pii_entities = [
    { type = "EMAIL",                    action = "ANONYMIZE" },
    { type = "PHONE",                    action = "ANONYMIZE" },
    { type = "NAME",                     action = "ANONYMIZE" },
    { type = "ADDRESS",                  action = "ANONYMIZE" },
    { type = "CREDIT_DEBIT_CARD_NUMBER", action = "BLOCK" },
    { type = "US_SOCIAL_SECURITY_NUMBER", action = "BLOCK" },
    { type = "US_BANK_ACCOUNT_NUMBER",   action = "BLOCK" }
  ]

  denied_topics = [
    {
      name       = "Investment_Advice"
      definition = "Any financial advice, stock recommendations..."
      examples   = ["What stocks should I buy?", ...]
    },
    {
      name       = "Medical_Diagnosis"
      definition = "Medical diagnoses or treatment recommendations..."
      examples   = ["I have a headache, what disease do I have?", ...]
    },
    {
      name       = "Legal_Advice"
      definition = "Specific legal advice or law interpretation..."
      examples   = ["Can I sue my employer?", ...]
    }
  ]

  word_filters = [
    "competitor_company_XYZ",
    "internal_password",
    "confidential"
  ]

  create_version = true  # Fixed version for production
}
```

**Development Guardrail:**
```hcl
module "development_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "dev-testing-guardrail-v2"
  description = "Development guardrail with relaxed settings"

  content_filters = [
    { type = "HATE",     input_strength = "MEDIUM", output_strength = "MEDIUM" },
    { type = "VIOLENCE", input_strength = "LOW",    output_strength = "MEDIUM" }
  ]

  pii_entities = [
    { type = "EMAIL",                    action = "ANONYMIZE" },
    { type = "CREDIT_DEBIT_CARD_NUMBER", action = "BLOCK" }
  ]

  create_version = false  # DRAFT version for testing
}
```

**Minimal Guardrail:**
```hcl
module "minimal_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "minimal-pii-guardrail-v2"
  description = "Minimal guardrail with PII protection only"

  pii_entities = [
    { type = "EMAIL", action = "ANONYMIZE" },
    { type = "PHONE", action = "ANONYMIZE" }
  ]

  create_version = true
}
```

---

## 3. CI/CD Pipeline s GitHub Actions

### Workflow architektúra

```
┌─────────────────────────────────────────────────────┐
│              Git Push to main/develop               │
└────────────────┬────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────┐
│                   VALIDATION                        │
│  ┌────────────────┐      ┌─────────────────┐       │
│  │ Terraform      │      │ Python Tests    │       │
│  │ Validate       │      │ (flake8)        │       │
│  └────────────────┘      └─────────────────┘       │
└────────────────┬────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────┐
│                   PLANNING                          │
│  ┌─────────────────────────────────────────────┐   │
│  │ Terraform Plan                              │   │
│  │ - Show changes                              │   │
│  │ - Save plan artifact                        │   │
│  └─────────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────────┘
                 ▼
┌─────────────────────────────────────────────────────┐
│                   DEPLOYMENT                        │
│  ┌─────────────────────────────────────────────┐   │
│  │ Terraform Apply                             │   │
│  │ - Apply saved plan                          │   │
│  │ - Output guardrail IDs                      │   │
│  │ - Create GitHub release                     │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### GitHub Actions Workflow

**Kompletný `.github/workflows/terraform.yml`:**

```yaml
name: 'Terraform CI/CD'

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

permissions:
  id-token: write    # Required for OIDC
  contents: write    # Required for GitHub releases

env:
  TF_VERSION: '1.5.0'
  AWS_REGION: 'eu-west-1'
  AWS_ROLE_ARN: 'arn:aws:iam::ACCOUNT_ID:role/GitHubActionsBedrockRole'

jobs:
  # Job 1: Terraform Validation
  terraform-validate:
    name: 'Terraform Validate'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -backend=false

      - name: Terraform Validate
        run: terraform validate

  # Job 2: Python Tests
  python-tests:
    name: 'Python Tests'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Dependencies
        run: |
          cd examples/python
          pip install -r requirements.txt

      - name: Lint Python Code
        run: |
          pip install flake8
          cd examples/python
          flake8 *.py --max-line-length=120

  # Job 3: Terraform Plan (Production)
  terraform-plan-prod:
    name: 'Terraform Plan (Production)'
    runs-on: ubuntu-latest
    needs: [terraform-validate, python-tests]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ env.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -var="environment=prod" -out=tfplan

      - name: Save Plan
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan-prod
          path: tfplan

  # Job 4: Terraform Apply (Production)
  terraform-apply-prod:
    name: 'Terraform Apply (Production)'
    runs-on: ubuntu-latest
    needs: [terraform-plan-prod]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment:
      name: production
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ env.AWS_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Terraform Init
        run: terraform init

      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: terraform-plan-prod

      - name: Terraform Apply
        run: terraform apply tfplan

      - name: Output Guardrail IDs
        run: terraform output -json guardrails_summary

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: release-${{ github.run_number }}
          name: Production Release ${{ github.run_number }}
          body: |
            ## Deployed Guardrails
            - Production Guardrail
            - Development Guardrail
            - Minimal Guardrail

            See job logs for Guardrail IDs.
```

### OIDC Authentication

**Prečo OIDC namiesto Access Keys?**

| Feature | Access Keys | OIDC |
|---------|-------------|------|
| **Bezpečnosť** | Long-lived credentials | Short-lived tokens |
| **Rotácia** | Manuálna | Automatická |
| **Secrets** | V GitHub secrets | Žiadne secrets |
| **Audit** | Ťažšie sledovať | Jednoduchý audit trail |
| **Best practice** | ❌ Not recommended | ✅ Recommended |

**Setup OIDC v AWS:**

1. **Vytvorenie OIDC Provider:**
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

2. **Vytvorenie IAM Role:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:username/repository:*"
        }
      }
    }
  ]
}
```

3. **Pripojenie policies:**
```bash
# Bedrock permissions
aws iam attach-role-policy \
  --role-name GitHubActionsBedrockRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess

# Backend access (inline policy)
aws iam put-role-policy \
  --role-name GitHubActionsBedrockRole \
  --policy-name TerraformBackendAccess \
  --policy-document file://backend-policy.json
```

**backend-policy.json:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bedrock-guardrails-terraform-state",
        "arn:aws:s3:::bedrock-guardrails-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/terraform-state-lock"
    }
  ]
}
```

---

## 4. Ako to všetko funguje spolu

### Deployment Flow (krok za krokom)

**1. Developer pushne zmeny do Git:**
```bash
git add main.tf
git commit -m "Add new guardrail configuration"
git push origin main
```

**2. GitHub Actions sa spustí automaticky:**

```
[Validation Phase]
├─ terraform-validate job
│  ├─ Checkout kódu
│  ├─ Setup Terraform
│  ├─ terraform fmt -check (kontrola formátovania)
│  ├─ terraform init -backend=false
│  └─ terraform validate (syntaktická kontrola)
│
└─ python-tests job
   ├─ Checkout kódu
   ├─ Setup Python 3.11
   ├─ pip install -r requirements.txt
   └─ flake8 *.py (linting)

[Planning Phase]
└─ terraform-plan-prod job
   ├─ Checkout kódu
   ├─ Setup Terraform
   ├─ Configure AWS (OIDC)
   │  └─ Získa dočasné credentials (1 hodina)
   ├─ terraform init
   │  └─ Pripojí sa na S3 backend
   ├─ terraform plan -var="environment=prod" -out=tfplan
   │  └─ Vypočíta zmeny (create/update/delete)
   └─ Upload tfplan ako artifact

[Deployment Phase]
└─ terraform-apply-prod job
   ├─ Checkout kódu
   ├─ Setup Terraform
   ├─ Configure AWS (OIDC)
   ├─ terraform init
   ├─ Download tfplan artifact
   ├─ terraform apply tfplan
   │  ├─ Vytvorí/aktualizuje guardraily v AWS
   │  ├─ Uloží state do S3
   │  └─ Zamkne state v DynamoDB
   ├─ terraform output -json guardrails_summary
   └─ Create GitHub Release
      └─ Tag: release-X
```

**3. Terraform vytvorí zdroje v AWS:**

```
[S3 Backend]
1. terraform init
   └─ Stiahne state z S3 (ak existuje)

[DynamoDB Lock]
2. terraform plan/apply
   ├─ Vytvorí lock záznam v DynamoDB
   │  └─ Zabraňuje súbežným run-om
   └─ Po dokončení uvoľní lock

[Bedrock Guardrails]
3. terraform apply
   ├─ module.production_guardrail
   │  ├─ aws_bedrock_guardrail.this (CREATE)
   │  │  └─ ID: abc123xyz
   │  └─ aws_bedrock_guardrail_version.this[0] (CREATE)
   │     └─ Version: 1
   │
   ├─ module.development_guardrail
   │  └─ aws_bedrock_guardrail.this (CREATE)
   │     └─ ID: def456uvw (DRAFT)
   │
   └─ module.minimal_guardrail
      ├─ aws_bedrock_guardrail.this (CREATE)
      │  └─ ID: ghi789rst
      └─ aws_bedrock_guardrail_version.this[0] (CREATE)
         └─ Version: 1

[State Update]
4. terraform apply (completed)
   └─ Uloží nový state do S3
      └─ s3://bedrock-guardrails-terraform-state/terraform.tfstate
```

**4. Output a dokumentácia:**

```bash
# Terraform output
terraform output guardrails_summary
{
  "production": {
    "arn": "arn:aws:bedrock:eu-west-1:123456789:guardrail/abc123",
    "id": "abc123",
    "version": "1"
  },
  "development": {
    "arn": "arn:aws:bedrock:eu-west-1:123456789:guardrail/def456",
    "id": "def456",
    "version": "DRAFT"
  },
  "minimal": {
    "arn": "arn:aws:bedrock:eu-west-1:123456789:guardrail/ghi789",
    "id": "ghi789",
    "version": "1"
  }
}
```

---

## 5. Python Integrácia

### Základné použitie

**basic_usage.py:**
```python
import boto3
import json
import os
from dotenv import load_dotenv

load_dotenv()

class BedrockGuardrailExample:
    def __init__(self):
        self.region = os.getenv('AWS_REGION', 'us-east-1')
        self.guardrail_id = os.getenv('GUARDRAIL_ID')
        self.guardrail_version = os.getenv('GUARDRAIL_VERSION', '1')
        self.model_id = os.getenv('BEDROCK_MODEL_ID',
                                  'anthropic.claude-3-sonnet-20240229-v1:0')

        self.client = boto3.client(
            service_name='bedrock-runtime',
            region_name=self.region
        )

    def invoke_with_guardrail(self, prompt: str, max_tokens: int = 1000):
        """
        Call Bedrock model with guardrail protection.
        """
        try:
            request_body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": max_tokens,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}]
                    }
                ]
            }

            response = self.client.invoke_model(
                modelId=self.model_id,
                guardrailIdentifier=self.guardrail_id,
                guardrailVersion=self.guardrail_version,
                body=json.dumps(request_body)
            )

            response_body = json.loads(response['body'].read())
            headers = response.get('ResponseMetadata', {}).get('HTTPHeaders', {})

            guardrail_action = headers.get('x-amzn-bedrock-guardrail-action', 'NONE')

            return {
                'success': True,
                'content': response_body.get('content', [{}])[0].get('text', ''),
                'guardrail_action': guardrail_action,
                'blocked': guardrail_action == 'BLOCKED'
            }

        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'blocked': True
            }
```

### Produkčný Chatbot

**chatbot_example.py:**
```python
class GuardedChatbot:
    """
    Production chatbot with integrated Bedrock Guardrails.
    """

    def __init__(self, model_id, guardrail_id, guardrail_version='1',
                 region='us-east-1', max_history=10):
        self.model_id = model_id
        self.guardrail_id = guardrail_id
        self.guardrail_version = guardrail_version
        self.region = region
        self.max_history = max_history

        self.client = boto3.client('bedrock-runtime', region_name=region)
        self.conversation_history = []
        self.blocked_attempts = 0

    def chat(self, user_message: str) -> Dict:
        """
        Main method for chatting with guardrail protection.
        """
        timestamp = datetime.now().isoformat()

        # Add user message to history
        self.conversation_history.append({
            'role': 'user',
            'content': [{'type': 'text', 'text': user_message}]
        })

        try:
            request_body = {
                'anthropic_version': 'bedrock-2023-05-31',
                'max_tokens': 2000,
                'messages': self._get_messages_for_api(),
                'temperature': 0.7
            }

            response = self.client.invoke_model(
                modelId=self.model_id,
                guardrailIdentifier=self.guardrail_id,
                guardrailVersion=self.guardrail_version,
                body=json.dumps(request_body)
            )

            response_body = json.loads(response['body'].read())
            headers = response.get('ResponseMetadata', {}).get('HTTPHeaders', {})
            guardrail_action = headers.get('x-amzn-bedrock-guardrail-action', 'NONE')

            if guardrail_action == 'BLOCKED':
                self.blocked_attempts += 1
                return self._handle_blocked_response(user_message, timestamp)

            assistant_message = response_body['content'][0]['text']

            # Add assistant response to history
            self.conversation_history.append({
                'role': 'assistant',
                'content': [{'type': 'text', 'text': assistant_message}]
            })

            self._trim_history()

            return {
                'success': True,
                'message': assistant_message,
                'timestamp': timestamp,
                'guardrail_action': guardrail_action,
                'usage': response_body.get('usage', {}),
                'blocked': False
            }

        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'timestamp': timestamp,
                'blocked': True
            }
```

### Response Headers a Metadata

**Analýza Guardrail Assessment:**

```python
# Response headers obsahujú detailné informácie
headers = response['ResponseMetadata']['HTTPHeaders']

# Hlavná akcia
action = headers.get('x-amzn-bedrock-guardrail-action')
# Možnosti: NONE, GUARDRAIL_INTERVENED, GUARDRAIL_BLOCKED

# Input assessment (JSON string)
input_assessment = json.loads(
    headers.get('x-amzn-bedrock-guardrail-input-assessment', '{}')
)

# Output assessment (JSON string)
output_assessment = json.loads(
    headers.get('x-amzn-bedrock-guardrail-output-assessment', '{}')
)

# Príklad input_assessment:
{
  "contentPolicy": {
    "filters": [
      {
        "type": "HATE",
        "confidence": "HIGH",
        "action": "BLOCKED"
      }
    ]
  },
  "sensitiveInformationPolicy": {
    "piiEntities": [
      {
        "type": "EMAIL",
        "action": "ANONYMIZED",
        "match": "user@example.com"
      }
    ]
  },
  "topicPolicy": {
    "topics": [
      {
        "name": "Investment_Advice",
        "type": "DENY",
        "action": "BLOCKED"
      }
    ]
  }
}
```

---

## 6. Best Practices a Odporúčania

### 1. Verzie Guardrailov

**Production vs Development:**

```hcl
# PRODUCTION - Always use fixed version
module "production_guardrail" {
  create_version = true
  version_description = "Production v1.0"
}

# In Python code
response = client.invoke_model(
    guardrailVersion='1'  # ✅ Fixed version
)

# DEVELOPMENT - Use DRAFT for testing
module "development_guardrail" {
  create_version = false  # DRAFT version
}

# In Python code
response = client.invoke_model(
    guardrailVersion='DRAFT'  # ✅ For testing only
)
```

**Prečo fixed version v produkcii?**
- Konzistentné správanie
- Žiadne neočakávané zmeny
- Možnosť rollback-u
- Audit trail

### 2. Granularita Filtrov

**Príklad stratégie:**

```
Environment   | Content Filters | PII Protection | Topics
--------------|----------------|----------------|--------
Production    | HIGH           | BLOCK/ANON     | All
Staging       | MEDIUM         | ANONYMIZE      | All
Development   | LOW            | ANONYMIZE      | Subset
Testing       | NONE           | ANONYMIZE      | None
```

### 3. Logovanie a Monitoring

**Čo logovať:**

```python
def log_guardrail_event(prompt, response, guardrail_action):
    """
    Log guardrail events for monitoring and analytics.
    """
    log_data = {
        'timestamp': datetime.now().isoformat(),
        'guardrail_action': guardrail_action,
        'prompt_hash': hashlib.sha256(prompt.encode()).hexdigest(),
        'blocked': guardrail_action == 'BLOCKED',
        'user_id': get_current_user_id(),
        'session_id': get_session_id()
    }

    # Send to CloudWatch, ELK, or other logging system
    logger.info('guardrail_event', extra=log_data)

    # If blocked, log additional details
    if guardrail_action == 'BLOCKED':
        logger.warning('guardrail_blocked', extra={
            **log_data,
            'assessment': response.get('assessment')
        })
```

**CloudWatch Metrics:**

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def publish_guardrail_metric(action):
    """
    Publish guardrail metrics to CloudWatch.
    """
    cloudwatch.put_metric_data(
        Namespace='BedrockGuardrails',
        MetricData=[
            {
                'MetricName': 'GuardrailActions',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [
                    {'Name': 'Action', 'Value': action},
                    {'Name': 'Environment', 'Value': 'production'}
                ]
            }
        ]
    )
```

### 4. Error Handling

**Robustné spracovanie chýb:**

```python
def invoke_with_retry(client, prompt, max_retries=3):
    """
    Invoke model with exponential backoff retry.
    """
    for attempt in range(max_retries):
        try:
            response = client.invoke_model(
                modelId=MODEL_ID,
                guardrailIdentifier=GUARDRAIL_ID,
                guardrailVersion='1',
                body=json.dumps(request_body)
            )
            return response

        except ClientError as e:
            error_code = e.response['Error']['Code']

            if error_code == 'ThrottlingException':
                # Exponential backoff
                wait_time = (2 ** attempt) + random.uniform(0, 1)
                time.sleep(wait_time)
                continue

            elif error_code == 'ValidationException':
                # Don't retry validation errors
                logger.error(f"Validation error: {e}")
                raise

            elif error_code == 'ResourceNotFoundException':
                # Guardrail doesn't exist
                logger.error(f"Guardrail not found: {GUARDRAIL_ID}")
                raise

            else:
                # Unknown error
                logger.error(f"Bedrock error: {e}")
                raise

    raise Exception(f"Max retries ({max_retries}) exceeded")
```

### 5. Testing Stratégia

**Unit testy pre guardraily:**

```python
import pytest
from moto import mock_bedrock_runtime

@mock_bedrock_runtime
def test_guardrail_blocks_hate_speech():
    """Test that guardrail blocks hate speech."""
    client = BedrockGuardrailExample()

    # Test prompt with hate speech
    result = client.invoke_with_guardrail(
        "Write a hateful comment about a group of people"
    )

    assert result['blocked'] == True
    assert result['guardrail_action'] == 'BLOCKED'

@mock_bedrock_runtime
def test_guardrail_anonymizes_pii():
    """Test that guardrail anonymizes PII data."""
    client = BedrockGuardrailExample()

    result = client.invoke_with_guardrail(
        "My email is john@example.com and phone is +1234567890"
    )

    assert result['blocked'] == False
    assert '[EMAIL]' in result['content']
    assert '[PHONE]' in result['content']

@mock_bedrock_runtime
def test_guardrail_blocks_investment_advice():
    """Test that guardrail blocks investment advice topic."""
    client = BedrockGuardrailExample()

    result = client.invoke_with_guardrail(
        "What stocks should I buy to make the most money?"
    )

    assert result['blocked'] == True
    assert 'Investment' in str(result.get('assessment', ''))
```

### 6. Bezpečnostné odporúčania

**Checklist:**

- [ ] **Nikdy neloguj citlivé dáta** (PII, heslá, API keys)
- [ ] **Používaj fixed versions v produkcii** (nie DRAFT)
- [ ] **Pravidelne audituj zablokované requesty**
- [ ] **Monitoruj falošné pozitívy** (legitimate requests blokované omylom)
- [ ] **Testuj guardraily pred deploymentom**
- [ ] **Používaj OIDC namiesto access keys**
- [ ] **Enkryptuj Terraform state** (S3 encryption enabled)
- [ ] **Implementuj rate limiting** (ochrana pred abuse)
- [ ] **Nastav alerting** (CloudWatch alarms pre vysoký počet blocknutých requestov)

---

## 7. Nákladová Optimalizácia

### Pricing Model

**AWS Bedrock Guardrails:**
- **Input processing**: $0.75 per 1,000 text units
- **Output processing**: $1.00 per 1,000 text units
- **1 text unit** ≈ 1,000 characters (ASCII) alebo 400 characters (Unicode)

**Príklad kalkulácia:**

```
Scenár: Chatbot s 10,000 konverzácií/mesiac
- Priemerná dĺžka vstupu: 500 znakov
- Priemerná dĺžka výstupu: 1,500 znakov

Input:
10,000 × 500 chars = 5,000,000 chars
5,000,000 / 1,000 = 5,000 text units
5,000 / 1,000 = 5 thousands
5 × $0.75 = $3.75

Output:
10,000 × 1,500 chars = 15,000,000 chars
15,000,000 / 1,000 = 15,000 text units
15,000 / 1,000 = 15 thousands
15 × $1.00 = $15.00

Total: $18.75/month
```

**Optimalizačné stratégie:**

1. **Cachuj odpovede** (ak to dáva zmysel)
```python
from functools import lru_cache

@lru_cache(maxsize=1000)
def get_cached_response(prompt_hash):
    # Return cached response if available
    pass
```

2. **Používaj lehšie guardraily pre non-critical use cases**
```hcl
# Minimal guardrail (len PII) je lacnejší ako full guardrail
module "minimal_guardrail" {
  pii_entities = [...]
  # No content filters, topics, or word filters
}
```

3. **Implementuj rate limiting**
```python
from ratelimit import limits, sleep_and_retry

@sleep_and_retry
@limits(calls=100, period=60)  # 100 requests per minute
def call_bedrock_with_guardrail(prompt):
    pass
```

### Infrastructure Costs

**S3 + DynamoDB:**
- S3 storage: ~$0.023 per GB/month (state file je < 1 MB)
- DynamoDB: Pay-per-request (prvých 1M requestov free)
- **Estimate**: < $1/month pre backend infraštruktúru

---

## 8. Riešenie Problémov

### Časté chyby a riešenia

#### 1. "ARN is invalid for the service region"

**Problém:**
```
Error: reading Bedrock Guardrail (...): ValidationException:
The provided ARN is invalid for the service region
```

**Príčina:**
- Guardrail vytvorený v inom regióne ako je nastavený v Terraform
- Stale state file odkazuje na neexistujúci guardrail

**Riešenie:**
```bash
# 1. Vyčisti state
aws s3 rm s3://bedrock-guardrails-terraform-state/terraform.tfstate

# 2. Zmaž staré guardraily
aws bedrock list-guardrails --region eu-west-1 | \
  jq -r '.guardrails[].id' | \
  xargs -I {} aws bedrock delete-guardrail --guardrail-identifier {} --region eu-west-1

# 3. Spusti terraform apply znova
terraform init -reconfigure
terraform apply
```

#### 2. "Guardrail name already exists"

**Problém:**
```
Error: ConflictException: Another guardrail in your account
already has this name.
```

**Riešenie:**
```bash
# Zmeň názov v main.tf
name = "prod-company-guardrail-v2"  # Add suffix

# Alebo zmaž existujúci
aws bedrock delete-guardrail \
  --guardrail-identifier EXISTING_ID \
  --region eu-west-1
```

#### 3. "State lock timeout"

**Problém:**
```
Error acquiring the state lock: ConditionalCheckFailedException
```

**Príčina:**
- Predchádzajúci terraform run nezavolal unlock
- Súbežný terraform run

**Riešenie:**
```bash
# Force unlock (use carefully!)
terraform force-unlock LOCK_ID

# Alebo vyčisti DynamoDB lock table
aws dynamodb scan --table-name terraform-state-lock --region eu-west-1 | \
  jq -r '.Items[].LockID.S' | \
  xargs -I {} aws dynamodb delete-item \
    --table-name terraform-state-lock \
    --key '{"LockID":{"S":"{}"}}' \
    --region eu-west-1
```

#### 4. "Access Denied" pri OIDC

**Problém:**
```
Error: Error assuming role: AccessDenied
```

**Kontroluj:**
```bash
# 1. Trust policy role
aws iam get-role --role-name GitHubActionsBedrockRole \
  | jq '.Role.AssumeRolePolicyDocument'

# 2. OIDC provider existuje
aws iam list-open-id-connect-providers | \
  grep token.actions.githubusercontent.com

# 3. Repository match v trust policy
# Must contain: "repo:username/repository:*"
```

---

## 9. Rozšírenia a Ďalší Vývoj

### Možné rozšírenia riešenia

#### 1. Multi-Environment Support

```hcl
# environments/dev.tfvars
environment = "dev"
aws_region  = "eu-west-1"
content_filter_strength = "MEDIUM"

# environments/prod.tfvars
environment = "prod"
aws_region  = "eu-west-1"
content_filter_strength = "HIGH"

# Usage
terraform apply -var-file="environments/prod.tfvars"
```

#### 2. Custom Content Filters

```hcl
# Add custom managed rules
module "custom_guardrail" {
  source = "./modules/bedrock-guardrail"

  # Custom regex patterns
  custom_regex_filters = [
    {
      name    = "credit_card_pattern"
      pattern = "\\d{4}-\\d{4}-\\d{4}-\\d{4}"
      action  = "BLOCK"
    }
  ]
}
```

#### 3. Multi-Region Deployment

```hcl
# Deploy to multiple regions
module "guardrail_eu" {
  source = "./modules/bedrock-guardrail"
  providers = {
    aws = aws.eu-west-1
  }
}

module "guardrail_us" {
  source = "./modules/bedrock-guardrail"
  providers = {
    aws = aws.us-east-1
  }
}
```

#### 4. Integration s Lambda

```python
# AWS Lambda function
import boto3
import json

bedrock = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    """
    Lambda function that uses guardrails.
    """
    prompt = event['prompt']

    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-sonnet-20240229-v1:0',
        guardrailIdentifier=os.environ['GUARDRAIL_ID'],
        guardrailVersion=os.environ['GUARDRAIL_VERSION'],
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 1000,
            'messages': [{'role': 'user', 'content': [{'type': 'text', 'text': prompt}]}]
        })
    )

    return {
        'statusCode': 200,
        'body': json.dumps(json.loads(response['body'].read()))
    }
```

#### 5. Guardrail Metrics Dashboard

```python
# CloudWatch Dashboard
import boto3

cloudwatch = boto3.client('cloudwatch')

dashboard_body = {
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["BedrockGuardrails", "BlockedRequests"],
                    [".", "PassedRequests"],
                    [".", "IntervenedRequests"]
                ],
                "period": 300,
                "stat": "Sum",
                "region": "eu-west-1",
                "title": "Guardrail Actions"
            }
        }
    ]
}

cloudwatch.put_dashboard(
    DashboardName='BedrockGuardrails',
    DashboardBody=json.dumps(dashboard_body)
)
```

---

## 10. Záver

### Kľúčové výhody riešenia

✅ **Bezpečnosť**
- Multi-layered ochrana (content, PII, topics, words)
- OIDC autentifikácia (žiadne long-lived credentials)
- Encrypted state storage

✅ **Automatizácia**
- GitOps workflow (push → deploy)
- Automatic testing a validation
- Zero-touch deployment

✅ **Modularita**
- Reusable Terraform module
- Ľahko prispôsobiteľné guardraily
- Škálovateľné riešenie

✅ **Production-ready**
- State management (S3 + DynamoDB)
- Version control guardrailov
- Comprehensive monitoring a logging

✅ **Developer Experience**
- Python SDK príklady
- Interactive chatbot demo
- Comprehensive documentation

### Použiteľnosť v praxi

**Ideálne pre:**
- Enterprise AI aplikácie
- Chatboty a virtuálni asistenti
- Content generation platformy
- Customer support automation
- Internal knowledge bases

**Prípady použitia:**

1. **Healthcare chatbot** - Blokuje medical advice, chráni HIPAA data
2. **Financial advisor** - Blokuje investment advice, chráni FIN data
3. **Customer support** - Filtruje toxický obsah, anonymizuje PII
4. **Content moderation** - Automatické filtrovanie nevhodného obsahu
5. **Internal tools** - Ochrana confidential dát, compliance

### Ďalšie kroky

Po implementácii riešenia odporúčam:

1. **Monitoring setup** - CloudWatch dashboards, alarms
2. **Load testing** - Testuj pod zaťažením
3. **Cost optimization** - Analyzuj usage patterns
4. **Security audit** - Pravidelne review policies a permissions
5. **Documentation** - Internal wiki pre tím

### Zdroje a odkazy

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [boto3 Bedrock Runtime](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-runtime.html)

---

## Autor

**Roman Čerešňák**
- AWS Community Builder
- DevOps Engineer
- [GitHub](https://github.com/romanceresnak)
- [LinkedIn](#)

---

*Tento článok bol vytvorený ako praktický návod na implementáciu AWS Bedrock Guardrails v produkcii s použitím Infrastructure as Code a CI/CD best practices.*

**Posledná aktualizácia:** Marec 2026

**Verzia:** 1.0
