# AWS Bedrock Guardrails - Terraform Infrastructure

Modulárna Terraform infraštruktúra pre AWS Bedrock Guardrails s Python príkladmi.

## 🚀 Rýchla inštalácia

```bash
# 1. Konfigurácia
cp terraform.tfvars.example terraform.tfvars
# Upravte aws_region a environment

# 2. Deploy
terraform init
terraform apply

# 3. Získajte Guardrail IDs
terraform output guardrails_summary
```

## 📁 Štruktúra

```
.
├── main.tf                          # 3 guardrail príklady (prod, dev, minimal)
├── variables.tf                     # Input premenné
├── outputs.tf                       # Output hodnoty
├── terraform.tfvars.example         # Konfiguračný template
├── modules/
│   └── bedrock-guardrail/          # Reusable Terraform modul
└── examples/
    └── python/                      # Python príklady použitia
        ├── basic_usage.py          # Základné testy
        ├── advanced_usage.py       # Pokročilá analýza
        └── chatbot_example.py      # Interaktívny chatbot
```

## 🔧 Terraform nasadenie

### Predpoklady

- Terraform >= 1.5.0
- AWS CLI nakonfigurované (`aws configure`)
- AWS Bedrock access (request v AWS Console → Bedrock → Model access)

### Konfigurácia

```bash
cp terraform.tfvars.example terraform.tfvars
```

Upravte `terraform.tfvars`:
```hcl
aws_region  = "us-east-1"
environment = "dev"
```

### Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Získanie Guardrail IDs

```bash
# Všetky guardraily
terraform output guardrails_summary

# Konkrétny guardrail
terraform output production_guardrail_id
terraform output production_guardrail_version
```

## 🐍 Python príklady

### Setup

```bash
cd examples/python
pip install -r requirements.txt
cp .env.example .env
```

Upravte `.env` s Guardrail ID z terraform output:
```env
GUARDRAIL_ID=abc-def-123
GUARDRAIL_VERSION=1
AWS_REGION=us-east-1
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
```

### Spustenie

```bash
# Základné testy (4 scenáre)
python basic_usage.py

# Pokročilá analýza s reportingom
python advanced_usage.py

# Interaktívny chatbot
python chatbot_example.py
```

## 📊 Dostupné guardraily v projekte

### 1. Production Guardrail
- **Content filters**: HATE, INSULTS, SEXUAL, VIOLENCE, MISCONDUCT (HIGH)
- **PII**: Email, Phone, Name, Address, Credit Card (ANONYMIZE/BLOCK)
- **Topics**: Investičné poradenstvo, zdravotné diagnózy, právne rady
- **Version**: Fixná verzia 1.0

### 2. Development Guardrail
- **Content filters**: HATE, VIOLENCE (MEDIUM/LOW)
- **PII**: Email, Credit Card
- **Version**: DRAFT

### 3. Minimal Guardrail
- **PII only**: Email, Phone (ANONYMIZE)
- **Version**: Fixná verzia 1.0

## 🎨 Customizácia

Pridajte vlastný guardrail v `main.tf`:

```hcl
module "my_guardrail" {
  source = "./modules/bedrock-guardrail"

  name        = "my-custom-guardrail"
  environment = var.environment

  content_filters = [
    {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
  ]

  pii_entities = [
    {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
  ]

  denied_topics = [
    {
      name       = "Custom_Topic"
      definition = "Popis témy na zablokovanie"
      examples   = ["príklad 1", "príklad 2"]
    }
  ]

  word_filters = ["blocked_word", "competitor_name"]

  create_version = true
}
```

## 📋 Podporované možnosti

### Content Filter Types
- `HATE` - Nenávistné prejavy
- `INSULTS` - Urážky
- `SEXUAL` - Sexuálny obsah
- `VIOLENCE` - Násilie
- `MISCONDUCT` - Nevhodné správanie
- `PROMPT_ATTACK` - Prompt injection útoky

### PII Entity Types (top 15)
- `EMAIL`, `PHONE`, `NAME`, `ADDRESS`
- `CREDIT_DEBIT_CARD_NUMBER`, `CREDIT_DEBIT_CARD_CVV`
- `US_SOCIAL_SECURITY_NUMBER`, `US_BANK_ACCOUNT_NUMBER`
- `IP_ADDRESS`, `USERNAME`, `PASSWORD`
- `AWS_ACCESS_KEY`, `AWS_SECRET_KEY`
- `URL`, `AGE`

### Strength Levels
- `NONE` - Bez filtrovania
- `LOW` - Nízka citlivosť
- `MEDIUM` - Stredná citlivosť
- `HIGH` - Vysoká citlivosť (production)

### PII Actions
- `BLOCK` - Zablokuje celý request
- `ANONYMIZE` - Nahradí údaj (napr. [EMAIL], [PHONE])

## 🔄 CI/CD s GitHub Actions

Projekt obsahuje GitHub Actions workflow pre automatické nasadenie:

- **Validate**: Terraform format a validate
- **Test**: Python lint
- **Plan**: Terraform plan pre dev/prod
- **Apply**: Manual deployment do dev/prod

### Setup GitHub Secrets

Pridajte do GitHub repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCESS_KEY_ID_PROD` (pre production)
- `AWS_SECRET_ACCESS_KEY_PROD` (pre production)

## 🗑️ Odstránenie

```bash
terraform destroy
```

## 🔧 Troubleshooting

### Problem: "Guardrail not found"
```bash
# Overte Guardrail ID
terraform output production_guardrail_id

# Skontrolujte v AWS
aws bedrock get-guardrail --guardrail-identifier <id> --region us-east-1
```

### Problem: "AccessDeniedException"
```bash
# Overte AWS credentials
aws sts get-caller-identity

# Potrebné IAM permissions:
# - bedrock:CreateGuardrail
# - bedrock:GetGuardrail
# - bedrock:UpdateGuardrail
# - bedrock:DeleteGuardrail
# - bedrock:TagResource
```

### Problem: "Model not available in region"
```bash
# Claude 3 je dostupný v:
# us-east-1, us-west-2, eu-central-1, eu-west-1

# Request access:
# AWS Console → Bedrock → Model access → Request access
```

### Problem: Python príklady - "Guardrail blocked"
```bash
# Toto je očakávané správanie pre niektoré testy
# Check assessment v response headers pre detaily

# Test v AWS Console:
# AWS Console → Bedrock → Guardrails → Select guardrail → Test tab
```

## 📚 Použitie v produkcii

### Best Practices

1. **Vždy použite fixnú verziu v produkcii**
   ```hcl
   create_version = true
   ```

2. **Nikdy DRAFT v produkcii**
   ```python
   guardrailVersion='1'  # ✓ Správne
   guardrailVersion='DRAFT'  # ✗ Zlé
   ```

3. **Logujte blocked attempts**
   ```python
   if blocked:
       logger.warning("Guardrail blocked", extra={'prompt': prompt_hash})
   ```

4. **Separujte dev/prod guardraily**
   - Dev: MEDIUM strength, DRAFT verzia
   - Prod: HIGH strength, fixná verzia

## 📖 Príklad použitia

```python
import boto3
import json

client = boto3.client('bedrock-runtime', region_name='us-east-1')

response = client.invoke_model(
    modelId='anthropic.claude-3-sonnet-20240229-v1:0',
    guardrailIdentifier='your-guardrail-id',
    guardrailVersion='1',
    body=json.dumps({
        'anthropic_version': 'bedrock-2023-05-31',
        'max_tokens': 1000,
        'messages': [{
            'role': 'user',
            'content': [{'type': 'text', 'text': 'Your prompt here'}]
        }]
    })
)

# Check if blocked
headers = response['ResponseMetadata']['HTTPHeaders']
action = headers.get('x-amzn-bedrock-guardrail-action', 'NONE')

if action == 'BLOCKED':
    print("Request was blocked by guardrail")
else:
    result = json.loads(response['body'].read())
    print(result['content'][0]['text'])
```

## 📄 License

MIT
