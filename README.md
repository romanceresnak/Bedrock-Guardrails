# AWS Bedrock Guardrails - Terraform Infrastructure

Modular Terraform infrastructure for AWS Bedrock Guardrails with Python examples.

## 🚀 Quick Start

```bash
# 1. Configuration
cp terraform.tfvars.example terraform.tfvars
# Edit aws_region and environment

# 2. Deploy
terraform init
terraform apply

# 3. Get Guardrail IDs
terraform output guardrails_summary
```

## 📁 Project Structure

```
.
├── main.tf                          # 3 guardrail examples (prod, dev, minimal)
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── terraform.tfvars.example         # Configuration template
├── modules/
│   └── bedrock-guardrail/          # Reusable Terraform module
└── examples/
    └── python/                      # Python usage examples
        ├── basic_usage.py          # Basic tests
        ├── advanced_usage.py       # Advanced analysis
        └── chatbot_example.py      # Interactive chatbot
```

## 🔧 Terraform Deployment

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured (`aws configure`)
- AWS Bedrock access (request in AWS Console → Bedrock → Model access)

### Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
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

### Get Guardrail IDs

```bash
# All guardrails
terraform output guardrails_summary

# Specific guardrail
terraform output production_guardrail_id
terraform output production_guardrail_version
```

## 🐍 Python Examples

### Setup

```bash
cd examples/python
pip install -r requirements.txt
cp .env.example .env
```

Edit `.env` with Guardrail ID from terraform output:
```env
GUARDRAIL_ID=abc-def-123
GUARDRAIL_VERSION=1
AWS_REGION=us-east-1
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
```

### Run

```bash
# Basic tests (4 scenarios)
python basic_usage.py

# Advanced analysis with reporting
python advanced_usage.py

# Interactive chatbot
python chatbot_example.py
```

## 📊 Available Guardrails

### 1. Production Guardrail
- **Content filters**: HATE, INSULTS, SEXUAL, VIOLENCE, MISCONDUCT (HIGH)
- **PII**: Email, Phone, Name, Address, Credit Card (ANONYMIZE/BLOCK)
- **Topics**: Investment advice, medical diagnosis, legal advice
- **Version**: Fixed version 1.0

### 2. Development Guardrail
- **Content filters**: HATE, VIOLENCE (MEDIUM/LOW)
- **PII**: Email, Credit Card
- **Version**: DRAFT

### 3. Minimal Guardrail
- **PII only**: Email, Phone (ANONYMIZE)
- **Version**: Fixed version 1.0

## 🎨 Customization

Add your own guardrail in `main.tf`:

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
      definition = "Description of topic to block"
      examples   = ["example 1", "example 2"]
    }
  ]

  word_filters = ["blocked_word", "competitor_name"]

  create_version = true
}
```

## 📋 Supported Options

### Content Filter Types
- `HATE` - Hate speech
- `INSULTS` - Insults and derogatory language
- `SEXUAL` - Sexual content
- `VIOLENCE` - Violence
- `MISCONDUCT` - Inappropriate behavior
- `PROMPT_ATTACK` - Prompt injection attacks

### PII Entity Types (top 15)
- `EMAIL`, `PHONE`, `NAME`, `ADDRESS`
- `CREDIT_DEBIT_CARD_NUMBER`, `CREDIT_DEBIT_CARD_CVV`
- `US_SOCIAL_SECURITY_NUMBER`, `US_BANK_ACCOUNT_NUMBER`
- `IP_ADDRESS`, `USERNAME`, `PASSWORD`
- `AWS_ACCESS_KEY`, `AWS_SECRET_KEY`
- `URL`, `AGE`

### Strength Levels
- `NONE` - No filtering
- `LOW` - Low sensitivity
- `MEDIUM` - Medium sensitivity
- `HIGH` - High sensitivity (production)

### PII Actions
- `BLOCK` - Blocks the entire request
- `ANONYMIZE` - Replaces data (e.g., [EMAIL], [PHONE])

## 🔄 CI/CD with GitHub Actions

Project includes GitHub Actions workflow for automatic deployment:

- **Validate**: Terraform format and validate
- **Test**: Python lint
- **Plan**: Terraform plan for dev/prod
- **Apply**: Manual deployment to dev/prod

### Setup GitHub Secrets

Add to GitHub repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCESS_KEY_ID_PROD` (for production)
- `AWS_SECRET_ACCESS_KEY_PROD` (for production)

## 🗑️ Cleanup

```bash
terraform destroy
```

## 🔧 Troubleshooting

### Problem: "Guardrail not found"
```bash
# Verify Guardrail ID
terraform output production_guardrail_id

# Check in AWS
aws bedrock get-guardrail --guardrail-identifier <id> --region us-east-1
```

### Problem: "AccessDeniedException"
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Required IAM permissions:
# - bedrock:CreateGuardrail
# - bedrock:GetGuardrail
# - bedrock:UpdateGuardrail
# - bedrock:DeleteGuardrail
# - bedrock:TagResource
```

### Problem: "Model not available in region"
```bash
# Claude 3 is available in:
# us-east-1, us-west-2, eu-central-1, eu-west-1

# Request access:
# AWS Console → Bedrock → Model access → Request access
```

### Problem: Python examples - "Guardrail blocked"
```bash
# This is expected behavior for some tests
# Check assessment in response headers for details

# Test in AWS Console:
# AWS Console → Bedrock → Guardrails → Select guardrail → Test tab
```

## 📚 Production Usage

### Best Practices

1. **Always use fixed version in production**
   ```hcl
   create_version = true
   ```

2. **Never use DRAFT in production**
   ```python
   guardrailVersion='1'  # ✓ Correct
   guardrailVersion='DRAFT'  # ✗ Wrong
   ```

3. **Log blocked attempts**
   ```python
   if blocked:
       logger.warning("Guardrail blocked", extra={'prompt': prompt_hash})
   ```

4. **Separate dev/prod guardrails**
   - Dev: MEDIUM strength, DRAFT version
   - Prod: HIGH strength, fixed version

## 📖 Usage Example

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
