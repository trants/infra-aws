# Hướng Dẫn Tạo Nhiều Dự Án Trong Cùng Shared VPC

## Tổng Quan

Với cấu trúc mới, bạn có thể tạo **nhiều dự án** trong cùng một **Shared VPC**. Mỗi dự án sẽ có:
- EC2 instances (có thể nhiều instances)
- RDS database
- Security Groups riêng

Tất cả đều dùng chung VPC để tiết kiệm cost (Year 0-2 approach).

## Cấu Trúc

```
shared-prod-use1-vpc (10.0.0.0/16)
├── Project: myapp
│   ├── EC2: myapp-prod-use1-ec2-api-01
│   ├── RDS: myapp-prod-use1-rds-mysql-primary
│   └── Security Groups: myapp-prod-use1-sg-api, myapp-prod-use1-sg-rds
│
└── Project: payment
    ├── EC2: payment-prod-use1-ec2-api-01, payment-prod-use1-ec2-api-02
    ├── RDS: payment-prod-use1-rds-postgres-primary
    └── Security Groups: payment-prod-use1-sg-api, payment-prod-use1-sg-rds
```

## Cấu Hình

### 1. Tạo file `terraform.tfvars`

Copy từ `terraform.tfvars.example` và cập nhật:

```hcl
aws_region = "us-east-1"
project    = "infra-aws"
environment = "prod"

cost_center = "engineering"
owner       = "platform-team"

ssh_allowed_cidrs = ["YOUR_PUBLIC_IP/32"]
ec2_key_name      = "your-keypair-name"

projects = {
  # Project 1: MyApp
  myapp = {
    project_short      = "myapp"
    project_full       = "my-application"
    ec2_purpose        = "api"
    ec2_instance_type  = "t3.small"
    ec2_count          = 1
    rds_engine         = "mysql"
    rds_instance_class = "db.t3.micro"
    db_name            = "myapp_db"
    db_username        = "myapp_user"
    password_ssm_param = "/myapp/prod/mysql/password"
  }

  # Project 2: Payment Service
  payment = {
    project_short      = "payment"
    project_full       = "payment-service"
    ec2_purpose        = "api"
    ec2_instance_type  = "t3.medium"
    ec2_count          = 2
    rds_engine         = "postgres"
    rds_instance_class = "db.t3.small"
    db_name            = "payment_db"
    db_username        = "payment_user"
    password_ssm_param = "/payment/prod/postgres/password"
  }
}
```

### 2. Tạo SSM Parameters cho Database Passwords

Trước khi apply, cần tạo SSM parameters cho database passwords:

```bash
# For myapp
aws ssm put-parameter \
  --name "/myapp/prod/mysql/password" \
  --value "your-secure-password" \
  --type "SecureString" \
  --region us-east-1

# For payment
aws ssm put-parameter \
  --name "/payment/prod/postgres/password" \
  --value "your-secure-password" \
  --type "SecureString" \
  --region us-east-1
```

### 3. Apply Terraform

```bash
cd environments/prod/us-east-1
terraform init
terraform plan
terraform apply
```

## Naming Convention

Tất cả resources tuân theo format:
```
{project_short}-{env}-{region}-{resource-type}-{purpose}-{suffix}
```

### Ví dụ Resources được tạo:

**Project: myapp**
- VPC: `shared-prod-use1-vpc` (shared)
- EC2: `myapp-prod-use1-ec2-api-01`
- RDS: `myapp-prod-use1-rds-mysql-primary`
- SG: `myapp-prod-use1-sg-api`, `myapp-prod-use1-sg-rds`

**Project: payment**
- EC2: `payment-prod-use1-ec2-api-01`, `payment-prod-use1-ec2-api-02`
- RDS: `payment-prod-use1-rds-postgres-primary`
- SG: `payment-prod-use1-sg-api`, `payment-prod-use1-sg-rds`

## Outputs

Sau khi apply, bạn có thể xem outputs:

```bash
terraform output
```

Outputs bao gồm:
- `vpc_id`: Shared VPC ID
- `projects`: Map của tất cả projects với resources của chúng
  - `myapp`: EC2 instances, RDS endpoint, Security Groups
  - `payment`: EC2 instances, RDS endpoint, Security Groups

## Thêm Project Mới

Để thêm project mới, chỉ cần thêm vào `projects` map trong `terraform.tfvars`:

```hcl
projects = {
  # ... existing projects ...
  
  newproject = {
    project_short      = "newproj"
    project_full       = "new-project"
    ec2_purpose        = "api"
    ec2_instance_type  = "t3.small"
    ec2_count          = 1
    rds_engine         = "mysql"
    rds_instance_class = "db.t3.micro"
    db_name            = "newproj_db"
    db_username        = "newproj_user"
    password_ssm_param = "/newproj/prod/mysql/password"
  }
}
```

Sau đó:
```bash
terraform plan  # Review changes
terraform apply # Apply new project
```

## Xóa Project

Để xóa project, remove nó khỏi `projects` map:

```hcl
projects = {
  myapp = { ... }
  # payment = { ... }  # Remove this
}
```

Sau đó:
```bash
terraform plan  # Review what will be destroyed
terraform apply # Destroy project resources
```

**Lưu ý:** RDS có `deletion_protection = true`, cần disable trước khi destroy:
```bash
aws rds modify-db-instance \
  --db-instance-identifier myapp-prod-use1-rds-mysql-primary \
  --no-deletion-protection \
  --apply-immediately
```

## Best Practices

1. **Naming**: Dùng `project_short` ngắn gọn (3-8 chars), lowercase
2. **SSM Parameters**: Tạo passwords trong SSM Parameter Store trước khi apply
3. **Security Groups**: Mỗi project có Security Groups riêng, tự động isolate
4. **Cost Allocation**: Tags `Project`, `CostCenter` giúp billing allocation
5. **Scaling**: Có thể tăng `ec2_count` để scale horizontal

## Migration từ Single Project

Nếu bạn đã có 1 project cũ, migration steps:

1. Backup existing resources
2. Update `terraform.tfvars` với format mới
3. Import existing resources vào state mới (nếu cần)
4. Run `terraform plan` để verify
5. Apply changes

## Troubleshooting

### Lỗi: SSM parameter not found
- Đảm bảo đã tạo SSM parameter trước khi apply
- Check parameter path trong `password_ssm_param`

### Lỗi: Duplicate resource names
- Mỗi project phải có `project_short` unique
- Check naming convention

### Lỗi: VPC subnet IP space exhausted
- Shared VPC có giới hạn IP space
- Có thể cần tách VPC khi có quá nhiều projects (> 10)

## Khi Nào Cần Tách VPC?

Khi scale lên, có thể cần migrate sang **Hybrid** hoặc **Separate VPC**:
- > 10 projects
- > 50 engineers
- Compliance requirements (PCI-DSS, HIPAA)
- Security incidents

Xem `docs/ARCHITECTURE_RECOMMENDATIONS.md` để biết thêm.

