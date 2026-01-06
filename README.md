# Terraform AWS Infrastructure

Terraform modules và configurations để deploy infrastructure trên AWS.

## 📋 Tổng quan

Dự án này cung cấp:
- **VPC Module**: Tạo VPC với public/private subnets, NAT gateway, Internet Gateway
- **EC2 Module**: Deploy EC2 instances với EIP, security groups
- **RDS Module**: Tạo RDS database instances (MySQL, PostgreSQL, MariaDB)
- **Security Groups Module**: Quản lý security groups cho app và database
- **Project Module**: Composition module gom EC2 + RDS + Security Groups cho một project

## 🏗️ Cấu trúc thư mục

```
.
├── environments/          # Environment-specific configurations
│   └── prod/
│       └── us-east-1/    # Region-specific config
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           ├── providers.tf
│           ├── data.tf
│           ├── terraform.tfvars.example
│           └── backend.hcl.example
├── modules/              # Reusable Terraform modules
│   ├── vpc/
│   ├── ec2/
│   ├── rds/
│   ├── security-groups/
│   └── project/
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured với credentials
- S3 bucket và DynamoDB table cho Terraform state (xem `backend.hcl.example`)

### Setup Backend

1. Tạo S3 bucket cho Terraform state (bucket name phải unique globally):
```bash
# Lấy AWS Account ID để tạo unique bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
BUCKET_NAME="terraform-state-${ACCOUNT_ID}-${REGION}"

# Tạo bucket
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

# Enable versioning (required for state management)
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption (recommended)
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access (security best practice)
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Bucket created: ${BUCKET_NAME}"
```

**Lưu ý:** Nếu bucket name đã tồn tại, bạn có thể:
- Thêm suffix: `terraform-state-${ACCOUNT_ID}-${REGION}-${RANDOM_SUFFIX}`
- Hoặc dùng tên công ty: `terraform-state-${COMPANY_NAME}-${REGION}`
- Hoặc check bucket hiện có: `aws s3 ls | grep terraform-state`

2. Tạo DynamoDB table cho state locking:
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${REGION}
```

3. Copy và config backend:
```bash
cd environments/prod/us-east-1
cp backend.hcl.example backend.hcl
# Edit backend.hcl với bucket name và region của bạn
```

### Deploy Infrastructure

1. Copy và edit terraform.tfvars:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars với config của bạn
```

2. Initialize Terraform:
```bash
terraform init -backend-config=backend.hcl
```

3. Plan:
```bash
terraform plan
```

4. Apply:
```bash
terraform apply
```

## 📝 Configuration

### Environment Variables

Xem `environments/prod/us-east-1/terraform.tfvars.example` để biết các variables cần config.

### Projects Configuration

Mỗi project trong `projects` map sẽ tạo:
- EC2 instances (số lượng configurable)
- RDS database instance
- Security groups (app và database)

Example:
```hcl
projects = {
  myapp = {
    project_short      = "myapp"
    project_full       = "my-application"
    ec2_purpose        = "api"
    ec2_instance_type  = "t3.small"
    ec2_count          = 2
    rds_engine         = "mysql"
    rds_instance_class = "db.t3.small"
    db_name            = "myapp_db"
    db_username        = "myapp_user"
    password_ssm_param = "/myapp/prod/mysql/password"
  }
}
```

## 🔒 Security

- **Database passwords**: Lưu trong AWS Systems Manager Parameter Store (SSM)
- **SSH access**: Chỉ allow từ specified CIDR blocks
- **Encryption**: 
  - RDS storage encrypted
  - EC2 root volumes encrypted
- **IAM**: EC2 instances có thể attach IAM instance profile (configurable)

## 📊 Outputs

Sau khi deploy, xem outputs:
```bash
terraform output
```

Outputs bao gồm:
- VPC information (ID, CIDR, ARN)
- Project resources (EC2 instances, RDS endpoints, security groups)

## 🔧 Modules

### VPC Module

Tạo VPC với:
- Public và private subnets
- Internet Gateway
- NAT Gateway(s) - single hoặc multi-AZ
- Route tables

### EC2 Module

Tạo EC2 instances với:
- Auto-assign public IP
- Optional Elastic IP
- Encrypted root volume
- Optional IAM instance profile
- User data support

### RDS Module

Tạo RDS instances với:
- Multi-engine support (MySQL, PostgreSQL, MariaDB)
- Encryption enabled
- Backup và maintenance windows
- Optional Performance Insights
- Optional enhanced monitoring

### Security Groups Module

Tạo security groups:
- App SG: HTTP/HTTPS từ specified CIDRs, optional SSH
- RDS SG: Database access từ App SG only

### Project Module

Composition module gom:
- Security Groups
- RDS instance
- EC2 instances (multiple, distributed across AZs)

## 🛠️ Best Practices

1. **State Management**: Luôn dùng S3 backend với DynamoDB locking
2. **Secrets**: Không commit `terraform.tfvars` hoặc files chứa secrets
3. **Versioning**: Pin Terraform và provider versions
4. **Tags**: Tất cả resources đều có tags cho cost allocation
5. **Multi-AZ**: EC2 instances được distribute across availability zones

## 📚 Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## 🤝 Contributing

1. Tạo feature branch
2. Make changes
3. Test với `terraform plan`
4. Submit pull request

## 📄 License

[Your License Here]

## 👥 Authors

Platform Team

