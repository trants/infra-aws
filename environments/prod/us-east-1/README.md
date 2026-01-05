# Production Environment - US East 1

## Naming Convention

Tất cả resources tuân theo naming convention:
```
{project}-{env}-{region}-{resource-type}-{purpose}-{suffix}
```

### Ví dụ:
- VPC: `infra-prod-use1-vpc`
- RDS: `infra-prod-use1-rds-mysql-primary`
- EC2: `infra-prod-use1-ec2-api-01`
- Security Group: `infra-prod-use1-sg-api`

## VPC Strategy

**Mô hình: Shared VPC (Year 0-2)**

- 1 VPC cho tất cả services trong environment này
- Tách biệt bằng Security Groups + Subnets
- Phù hợp cho early stage (< 2 năm, < 50 engineers)

## Standard Tags

Tất cả resources có các tags sau:
- `Project`: Full project name
- `Environment`: dev, staging, prod
- `Region`: AWS region
- `ManagedBy`: terraform
- `CostCenter`: For billing allocation
- `Owner`: Team responsible
- `Tier`: app, data, cache
- `Service`: api, web, worker, database

## Setup

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update values trong `terraform.tfvars`:
   - `ssh_allowed_cidrs`: Your public IP
   - `ec2_key_name`: Your EC2 key pair name
   - `project_short`: Short project identifier
3. Initialize Terraform:
   ```bash
   terraform init
   ```
4. Plan changes:
   ```bash
   terraform plan
   ```
5. Apply:
   ```bash
   terraform apply
   ```

## Resources Created

- VPC với public và private subnets
- NAT Gateway (single, cost-optimized)
- Security Groups (app, rds)
- RDS MySQL instance
- EC2 instance với EIP

## Migration Path

Khi scale lên (> 5 projects, > 50 engineers):
- Có thể migrate sang Hybrid approach (shared + separate VPCs)
- Hoặc Separate VPC per project
- Xem `docs/ARCHITECTURE_RECOMMENDATIONS.md` để biết thêm

