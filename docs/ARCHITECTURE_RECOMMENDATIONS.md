# Đánh Giá Kiến Trúc Hạ Tầng Multi-Project

## 1. NAMING CONVENTION

### 1.1. Đánh Giá Hiện Trạng

**Cấu trúc hiện tại:**
```
VPC: prod-use1-vpc
RDS: prod-use1-mysql
EC2: prod-use1-ec2-app
SG:  prod-use1-sg-app
```

**Vấn đề:**
- ❌ Thiếu project identifier → không phân biệt được dự án
- ❌ Không có resource type prefix rõ ràng (rds-, ec2-, sg-)
- ❌ Khó truy vết billing theo project
- ❌ Khó filter trong CloudWatch, CloudTrail
- ❌ Khi scale nhiều project sẽ bị conflict

### 1.2. Naming Convention Đề Xuất

**Format chuẩn:**
```
{project}-{env}-{region}-{resource-type}-{purpose}-{optional-suffix}
```

**Quy tắc:**
1. **Project**: 3-8 ký tự, lowercase, alphanumeric + hyphen
   - Ví dụ: `myapp`, `payment`, `auth-svc`
2. **Environment**: `dev`, `staging`, `prod`
3. **Region**: AWS region short code
   - `use1` (us-east-1), `usw2` (us-west-2), `euw1` (eu-west-1)
4. **Resource Type**: prefix rõ ràng
   - `vpc`, `rds`, `ec2`, `sg`, `alb`, `s3`, `sns`, `sqs`
5. **Purpose**: mô tả chức năng
   - `api`, `web`, `worker`, `mysql`, `postgres`, `redis`
6. **Optional Suffix**: số thứ tự nếu có nhiều instance
   - `-01`, `-primary`, `-replica`

### 1.3. Ví Dụ Cụ Thể

#### VPC (Shared hoặc Per-Project)
```
# Shared VPC cho nhiều project
shared-prod-use1-vpc

# VPC riêng cho từng project
myapp-prod-use1-vpc
payment-prod-use1-vpc
```

#### RDS
```
myapp-prod-use1-rds-mysql-primary
myapp-prod-use1-rds-mysql-replica-01
payment-prod-use1-rds-postgres
```

#### EC2
```
myapp-prod-use1-ec2-api-01
myapp-prod-use1-ec2-api-02
myapp-prod-use1-ec2-worker
payment-prod-use1-ec2-web
```

#### Security Groups
```
myapp-prod-use1-sg-api
myapp-prod-use1-sg-rds
myapp-prod-use1-sg-alb
payment-prod-use1-sg-web
```

#### ALB
```
myapp-prod-use1-alb-api
myapp-prod-use1-alb-internal
```

#### S3
```
myapp-prod-use1-s3-app-logs
myapp-prod-use1-s3-app-backups
payment-prod-use1-s3-transactions
```

#### SNS Topics
```
myapp-prod-use1-sns-alerts
myapp-prod-use1-sns-deployments
```

### 1.4. Tags Strategy (Bổ Sung Cho Naming)

**Standard Tags (bắt buộc):**
```hcl
tags = {
  Project     = "myapp"
  Environment = "prod"
  Region      = "us-east-1"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"  # cho billing
  Owner       = "platform-team"
  Tier        = "app" | "data" | "cache"
  Service     = "api" | "worker" | "web"
}
```

**Lợi ích:**
- Filter billing theo `Project` tag
- CloudWatch metrics theo `Service` tag
- Compliance audit theo `Environment` tag
- Cost allocation reports tự động

### 1.5. Implementation Pattern

**Tạo locals trong main.tf:**
```hcl
locals {
  project_short = "myapp"  # hoặc var.project_short
  env_short     = var.environment
  region_short  = "use1"
  
  name_prefix = "${local.project_short}-${local.env_short}-${local.region_short}"
  
  # Resource-specific naming
  vpc_name     = "${local.name_prefix}-vpc"
  rds_name     = "${local.name_prefix}-rds-mysql"
  ec2_name     = "${local.name_prefix}-ec2-api"
  sg_app_name  = "${local.name_prefix}-sg-api"
  sg_rds_name  = "${local.name_prefix}-sg-rds"
}
```

---

## 2. VPC STRATEGY

### 2.1. Phân Tích 2 Mô Hình

#### Mô Hình A: Shared VPC (1 VPC cho nhiều project)

**Cấu trúc:**
```
shared-prod-use1-vpc (10.0.0.0/16)
├── Project A resources
├── Project B resources
└── Project C resources
```

**Ưu điểm:**
✅ **Cost**: 
- 1 NAT Gateway cho tất cả (tiết kiệm ~$32/tháng mỗi NAT)
- 1 VPC endpoint cho S3/DynamoDB (nếu dùng)
- Shared infrastructure (ALB, WAF) có thể reuse

✅ **Networking đơn giản:**
- Không cần VPC Peering
- Không cần Transit Gateway
- Service discovery dễ (cùng VPC)

✅ **Operation:**
- Centralized network management
- Dễ monitor traffic flow
- DNS resolution đơn giản

**Nhược điểm:**
❌ **Security:**
- Blast radius lớn: lỗi 1 project có thể ảnh hưởng toàn VPC
- Security Group rules phức tạp hơn (cần manage nhiều project)
- Khó isolation hoàn toàn giữa các project
- Compliance: một số industry (healthcare, finance) yêu cầu network isolation

❌ **IP Space:**
- Phải plan CIDR cẩn thận từ đầu
- Risk hết IP nếu scale nhiều project
- Khó migrate project ra ngoài sau này

❌ **Billing:**
- Khó allocate cost chính xác cho từng project
- NAT Gateway cost phải chia manual

❌ **Quản lý:**
- Team A có thể vô tình thay đổi config ảnh hưởng Team B
- Terraform state lớn, risk conflict khi apply
- Khó enforce network policies riêng cho từng project

#### Mô Hình B: Separate VPC (1 VPC per project/environment)

**Cấu trúc:**
```
myapp-prod-use1-vpc (10.0.0.0/16)
payment-prod-use1-vpc (10.1.0.0/16)
auth-prod-use1-vpc (10.2.0.0/16)
```

**Ưu điểm:**
✅ **Security:**
- Complete isolation giữa các project
- Blast radius nhỏ: lỗi chỉ ảnh hưởng 1 project
- Dễ enforce security policies riêng
- Compliance-friendly (HIPAA, PCI-DSS)

✅ **Quản lý:**
- Terraform state tách biệt → ít conflict
- Team tự quản lý VPC của mình
- Dễ migrate project sang account khác
- Clear ownership

✅ **Billing:**
- Cost allocation rõ ràng (VPC tag = project)
- NAT Gateway cost thuộc về project đó
- Dễ track và optimize cost per project

✅ **Networking:**
- IP space độc lập, không lo conflict
- Có thể dùng CIDR khác nhau cho từng project
- Dễ scale: thêm VPC mới không ảnh hưởng cũ

**Nhược điểm:**
❌ **Cost:**
- Mỗi VPC cần NAT Gateway riêng (~$32/tháng + data transfer)
- VPC endpoints phải tạo lại cho mỗi VPC
- Tăng chi phí khi có nhiều project nhỏ

❌ **Networking phức tạp:**
- Cần VPC Peering hoặc Transit Gateway để connect
- Service discovery phức tạp hơn (PrivateLink, DNS)
- Routing rules phải config manual

❌ **Operation:**
- Nhiều VPC = nhiều điểm quản lý
- Monitoring phải aggregate từ nhiều VPC
- Centralized logging phức tạp hơn

### 2.2. Khi Nào Dùng Mô Hình Nào?

#### Dùng Shared VPC khi:
1. **Startup / Small scale:**
   - < 5 projects
   - Team nhỏ (< 10 người)
   - Budget hạn chế

2. **Projects có trust level cao:**
   - Cùng team phát triển
   - Cùng compliance requirements
   - Cần share resources (Redis, Elasticsearch cluster)

3. **Microservices cùng domain:**
   - Các service thuộc 1 product lớn
   - Cần communicate với nhau thường xuyên
   - Service mesh (Istio, Linkerd) dễ deploy

4. **Cost optimization là ưu tiên:**
   - Projects nhỏ, traffic thấp
   - Không cần strict isolation

#### Dùng Separate VPC khi:
1. **Enterprise / Multi-tenant:**
   - > 5 projects
   - Nhiều teams độc lập
   - Cần clear ownership

2. **Compliance requirements:**
   - Healthcare (HIPAA)
   - Finance (PCI-DSS)
   - Government (FedRAMP)
   - Yêu cầu network isolation

3. **Projects có risk profile khác nhau:**
   - Production vs experimental
   - Internal vs customer-facing
   - High-security vs low-security

4. **Scale lâu dài:**
   - Dự kiến tăng trưởng nhanh
   - Cần flexibility để migrate
   - Multi-region deployment

### 2.3. Thực Tế Startup Lớn Đã Làm Gì?

#### Giai Đoạn Phát Triển Của Startup

**Phase 1: Early Stage (0-2 năm, < 50 engineers)**
```
Thực tế: DÙNG CHUNG VPC
- 1 VPC cho tất cả services
- Tách biệt bằng Security Groups + Subnets
- Tiết kiệm cost là ưu tiên
```

**Ví dụ thực tế:**
- **Stripe** (early days): 1 VPC cho tất cả, tách bằng namespaces
- **Shopify** (pre-IPO): Shared VPC với subnet per service
- **Most YC startups**: Shared VPC cho đến khi scale

**Lý do:**
- Team nhỏ, trust level cao
- Cost optimization quan trọng
- Networking đơn giản, dễ debug
- Chưa cần compliance strict

---

**Phase 2: Growth Stage (2-5 năm, 50-200 engineers)**
```
Thực tế: HYBRID APPROACH
- Shared VPC cho infrastructure chung
- Separate VPC cho critical/production services
- Dev/Staging: Shared VPC
- Prod: Bắt đầu tách VPC cho services quan trọng
```

**Ví dụ thực tế:**
- **Airbnb** (2015-2018): 
  - Shared VPC cho dev/staging
  - Separate VPC cho payment, booking (prod)
  - Transit Gateway để connect
- **Uber** (pre-IPO):
  - Shared VPC cho internal tools
  - Separate VPC cho rider app, driver app, payment

**Lý do:**
- Một số services cần isolation (payment, auth)
- Compliance bắt đầu quan trọng (PCI-DSS cho payment)
- Team lớn hơn, cần clear ownership
- Cost vẫn quan trọng nhưng security cũng vậy

---

**Phase 3: Scale Stage (5+ năm, 200+ engineers, IPO/post-IPO)**
```
Thực tế: SEPARATE VPC PER SERVICE/TEAM
- Mỗi service/team có VPC riêng
- Hundreds of VPCs
- Transit Gateway + Service Mesh
- Centralized networking team
```

**Ví dụ thực tế:**
- **Netflix** (hiện tại):
  - **Hundreds of VPCs** (mỗi microservice team có VPC riêng)
  - Transit Gateway để connect tất cả
  - Service mesh (Envoy) cho service discovery
  - Centralized networking team quản lý routing policies
- **Airbnb** (hiện tại):
  - Separate VPC per service domain
  - VPC per environment (dev, staging, prod)
  - ~50-100 VPCs total
- **Uber** (hiện tại):
  - VPC per service team
  - Multi-region với Transit Gateway
  - Service mesh (Envoy) cho cross-VPC communication

**Lý do:**
- Team autonomy: mỗi team tự quản lý infrastructure
- Security isolation: blast radius nhỏ
- Compliance: nhiều services cần isolation
- Cost không còn là vấn đề lớn (đã IPO, có budget)
- Scale: cần flexibility để scale độc lập

---

### 2.4. Hybrid Approach (Khuyến Nghị Thực Tế)

**Mô hình thực tế nhiều startup đang dùng (Phase 2):**

```
# Shared VPC cho infrastructure chung
shared-prod-use1-vpc
├── Monitoring (Prometheus, Grafana)
├── Logging (ELK stack, CloudWatch)
├── CI/CD runners (Jenkins, GitLab runners)
└── Shared services (Redis cluster, Elasticsearch)

# Separate VPC cho critical applications
myapp-prod-use1-vpc          # Main application
payment-prod-use1-vpc        # Payment (PCI-DSS)
auth-prod-use1-vpc           # Authentication service

# Connect via Transit Gateway
transit-gateway-prod-use1
├── Attachment: shared-prod-use1-vpc
├── Attachment: myapp-prod-use1-vpc
├── Attachment: payment-prod-use1-vpc
└── Attachment: auth-prod-use1-vpc
```

**Lợi ích:**
- Infrastructure chung → tiết kiệm cost (~$32/tháng × số VPC)
- Applications tách biệt → security + ownership rõ
- Có thể connect khi cần → flexibility
- Migration path rõ ràng khi scale

---

### 2.5. Khi Nào Chuyển Từ Shared Sang Separate?

**Red Flags - Cần tách VPC ngay:**

1. **Security incidents:**
   - Lỗi 1 service ảnh hưởng toàn VPC
   - Khó isolate được vấn đề

2. **Compliance requirements:**
   - Payment service → cần PCI-DSS → tách VPC
   - Healthcare data → cần HIPAA → tách VPC
   - Customer PII → cần isolation → tách VPC

3. **Team conflicts:**
   - Team A vô tình thay đổi config ảnh hưởng Team B
   - Terraform state conflicts thường xuyên
   - Khó enforce policies riêng

4. **Billing issues:**
   - Khó allocate cost cho từng team
   - Finance team yêu cầu cost breakdown

5. **Scale issues:**
   - Hết IP space trong VPC
   - Quá nhiều resources trong 1 VPC (AWS limits)
   - Network performance degradation

**Timeline thực tế:**
- **Year 0-2**: Shared VPC ✅
- **Year 2-3**: Hybrid (shared + một vài separate) ✅
- **Year 3+**: Separate VPC per service (nếu scale lớn) ✅

---

### 2.6. Best Practice từ Enterprise

**Netflix, Airbnb, Uber pattern (hiện tại):**
- **Separate VPC per service/team** (hundreds of VPCs)
- Dùng **Transit Gateway** để connect
- **Centralized networking team** quản lý routing policies
- **Service mesh** (Envoy, Istio) cho service discovery cross-VPC
- **VPC endpoints** cho AWS services (S3, DynamoDB) để tránh NAT Gateway cost

**AWS Well-Architected Framework khuyến nghị:**
- Start với Shared VPC nếu team nhỏ (< 10 người)
- Migrate sang Separate VPC khi:
  - Team > 10 người
  - Projects > 5
  - Cần compliance isolation
  - Cost allocation quan trọng
  - Có security incidents

**Thực tế từ AWS customers:**
- **70% startups** (< 2 năm): Shared VPC
- **50% growth companies** (2-5 năm): Hybrid
- **80% enterprises** (5+ năm): Separate VPC per service

---

## 3. KHUYẾN NGHỊ CUỐI CÙNG

### 3.1. Naming Convention

**✅ Áp dụng ngay:**
```
Format: {project}-{env}-{region}-{resource-type}-{purpose}

Ví dụ:
- myapp-prod-use1-vpc
- myapp-prod-use1-rds-mysql
- myapp-prod-use1-ec2-api-01
- myapp-prod-use1-sg-api
- myapp-prod-use1-alb-api
```

**✅ Standard tags (bắt buộc):**
- Project, Environment, Region, ManagedBy, CostCenter, Owner, Tier, Service

### 3.2. VPC Strategy

**✅ Khuyến nghị cho hệ thống multi-project lâu dài:**

**Phase 1 (Hiện tại - < 5 projects):**
- Dùng **Shared VPC** với naming convention mới
- Tách biệt bằng Security Groups + Subnets
- Tag rõ ràng để billing allocation

**Phase 2 (Khi scale - > 5 projects hoặc compliance yêu cầu):**
- Migrate sang **Separate VPC per project**
- Dùng **Transit Gateway** để connect
- Giữ 1 Shared VPC cho infrastructure chung (monitoring, logging)

**Migration path:**
1. Tạo VPC mới cho project mới
2. Migrate project cũ dần dần (blue-green)
3. Dọn dẹp Shared VPC sau khi migrate xong

### 3.3. Implementation Checklist

**Naming:**
- [ ] Update locals trong main.tf với project prefix
- [ ] Update tất cả modules để dùng naming convention mới
- [ ] Add standard tags vào tất cả resources
- [ ] Document naming convention trong README

**VPC:**
- [ ] Đánh giá số lượng projects hiện tại và dự kiến
- [ ] Quyết định Shared vs Separate dựa trên requirements
- [ ] Nếu Separate: plan CIDR blocks (10.0.0.0/16, 10.1.0.0/16, ...)
- [ ] Setup Transit Gateway nếu cần connect nhiều VPC
- [ ] Document VPC strategy và migration path

---

## 4. VÍ DỤ TERRAFORM CODE

### 4.1. Naming Convention Implementation

```hcl
# environments/prod/us-east-1/main.tf
locals {
  project_short = "myapp"  # hoặc var.project_short
  env_short     = var.environment
  region_short  = "use1"
  
  name_prefix = "${local.project_short}-${local.env_short}-${local.region_short}"
  
  # Resource names
  vpc_name     = "${local.name_prefix}-vpc"
  rds_name     = "${local.name_prefix}-rds-mysql"
  ec2_api_name = "${local.name_prefix}-ec2-api"
  sg_api_name  = "${local.name_prefix}-sg-api"
  sg_rds_name  = "${local.name_prefix}-sg-rds"
  alb_api_name = "${local.name_prefix}-alb-api"
  
  # Standard tags
  base_tags = {
    Project     = local.project_short
    Environment = local.env_short
    Region      = var.aws_region
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
    Owner       = "platform-team"
  }
}

module "vpc" {
  source = "../../../modules/vpc"
  name   = local.vpc_name
  # ...
  tags = local.base_tags
}

module "rds" {
  source = "../../../modules/rds"
  name_prefix = local.name_prefix
  # ...
  tags = merge(local.base_tags, {
    Tier    = "data"
    Service = "database"
  })
}
```

### 4.2. Separate VPC per Project

```hcl
# environments/prod/us-east-1/myapp/main.tf
module "vpc" {
  source = "../../../../modules/vpc"
  name   = "myapp-prod-use1-vpc"
  cidr   = "10.0.0.0/16"  # Project A
  # ...
}

# environments/prod/us-east-1/payment/main.tf
module "vpc" {
  source = "../../../../modules/vpc"
  name   = "payment-prod-use1-vpc"
  cidr   = "10.1.0.0/16"  # Project B
  # ...
}
```

### 4.3. Transit Gateway Setup (nếu cần connect)

```hcl
# environments/prod/us-east-1/shared/transit-gateway.tf
resource "aws_ec2_transit_gateway" "main" {
  description = "Transit Gateway for prod us-east-1"
  
  tags = {
    Name = "shared-prod-use1-tgw"
  }
}

# Attach VPCs
resource "aws_ec2_transit_gateway_vpc_attachment" "myapp" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = module.myapp_vpc.vpc_id
  subnet_ids         = module.myapp_vpc.private_subnet_ids
}

resource "aws_ec2_transit_gateway_vpc_attachment" "payment" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = module.payment_vpc.vpc_id
  subnet_ids         = module.payment_vpc.private_subnet_ids
}
```

---

## 5. TÀI LIỆU THAM KHẢO

- AWS Well-Architected Framework: Network Design
- HashiCorp Terraform AWS Provider Best Practices
- AWS VPC Design Guide
- Netflix Cloud Architecture Patterns
- AWS Cost Allocation Tags Best Practices

