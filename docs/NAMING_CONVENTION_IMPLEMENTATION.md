# Hướng Dẫn Triển Khai Naming Convention

## Cấu Trúc Đề Xuất

### Format Chuẩn
```
{project}-{env}-{region}-{resource-type}-{purpose}-{suffix}
```

### Ví Dụ Cụ Thể

| Resource | Naming Pattern | Ví Dụ |
|----------|---------------|-------|
| VPC | `{project}-{env}-{region}-vpc` | `myapp-prod-use1-vpc` |
| RDS | `{project}-{env}-{region}-rds-{engine}-{role}` | `myapp-prod-use1-rds-mysql-primary` |
| EC2 | `{project}-{env}-{region}-ec2-{purpose}-{index}` | `myapp-prod-use1-ec2-api-01` |
| Security Group | `{project}-{env}-{region}-sg-{purpose}` | `myapp-prod-use1-sg-api` |
| ALB | `{project}-{env}-{region}-alb-{purpose}` | `myapp-prod-use1-alb-api` |
| S3 | `{project}-{env}-{region}-s3-{purpose}` | `myapp-prod-use1-s3-logs` |
| SNS | `{project}-{env}-{region}-sns-{purpose}` | `myapp-prod-use1-sns-alerts` |

## Implementation trong Terraform

### 1. Update variables.tf

```hcl
variable "project" {
  type        = string
  description = "Project identifier (3-8 chars, lowercase)"
  default     = "myapp"
}

variable "environment" {
  type        = string
  description = "Environment: dev, staging, prod"
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
```

### 2. Update main.tf với locals

```hcl
locals {
  # Region short code mapping
  region_short_map = {
    us-east-1      = "use1"
    us-west-2      = "usw2"
    eu-west-1      = "euw1"
    ap-southeast-1 = "apse1"
  }
  
  region_short = local.region_short_map[var.aws_region]
  
  # Name prefix: project-env-region
  name_prefix = "${var.project}-${var.environment}-${local.region_short}"
  
  # Resource-specific names
  vpc_name = "${local.name_prefix}-vpc"
  
  # Standard tags
  base_tags = {
    Project     = var.project
    Environment = var.environment
    Region      = var.aws_region
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    Owner       = "platform-team"
  }
}
```

### 3. Update Modules

#### VPC Module
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block = var.cidr
  
  tags = merge(var.tags, {
    Name = var.name  # e.g., myapp-prod-use1-vpc
  })
}
```

#### RDS Module
```hcl
# modules/rds/main.tf
resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-rds-${var.engine}-${var.role}"
  # ...
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-${var.engine}-${var.role}"
    Tier = "data"
  })
}
```

#### EC2 Module
```hcl
# modules/ec2/main.tf
resource "aws_instance" "this" {
  # ...
  
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ec2-${var.purpose}-${format("%02d", var.instance_index)}"
    Tier    = "app"
    Service = var.purpose
  })
}
```

#### Security Groups Module
```hcl
# modules/security-groups/main.tf
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-sg-${var.purpose}"
  description = "Security group for ${var.purpose}"
  # ...
  
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-sg-${var.purpose}"
    Tier    = "app"
    Service = var.purpose
  })
}
```

## Multi-Project Example

### Project A: myapp
```hcl
# environments/prod/us-east-1/myapp/main.tf
locals {
  project_short = "myapp"
  name_prefix   = "${local.project_short}-prod-use1"
}

module "vpc" {
  source = "../../../../modules/vpc"
  name   = "${local.name_prefix}-vpc"
  # ...
}

module "rds" {
  source = "../../../../modules/rds"
  name_prefix = local.name_prefix
  # ...
}
```

### Project B: payment
```hcl
# environments/prod/us-east-1/payment/main.tf
locals {
  project_short = "payment"
  name_prefix   = "${local.project_short}-prod-use1"
}

module "vpc" {
  source = "../../../../modules/vpc"
  name   = "${local.name_prefix}-vpc"
  # ...
}
```

## Migration Checklist

- [ ] Update `variables.tf` với project identifier
- [ ] Tạo `locals` block với naming logic
- [ ] Update tất cả modules để dùng naming convention mới
- [ ] Update `main.tf` ở mỗi environment
- [ ] Test với `terraform plan` trước khi apply
- [ ] Document naming convention trong README
- [ ] Train team về convention mới

## Validation Rules

1. **Project name**: 3-8 chars, lowercase, alphanumeric + hyphen
2. **Environment**: Chỉ `dev`, `staging`, `prod`
3. **Region short**: Phải map đúng với AWS region
4. **Resource type**: Phải có prefix rõ ràng (rds-, ec2-, sg-, alb-)
5. **Purpose**: Mô tả chức năng, không dùng generic names

## Common Mistakes to Avoid

❌ **Không dùng:**
- `prod-vpc` (thiếu project)
- `myapp-prod-rds` (thiếu region)
- `myapp-prod-use1-mysql` (thiếu resource type prefix)
- `myapp-prod-use1-ec2` (thiếu purpose)

✅ **Nên dùng:**
- `myapp-prod-use1-vpc`
- `myapp-prod-use1-rds-mysql-primary`
- `myapp-prod-use1-ec2-api-01`
- `myapp-prod-use1-sg-api`

