# Hướng dẫn kết nối Navicat với RDS Database

## Tình trạng hiện tại

- RDS database nằm trong **private subnet** (không public)
- Security group chỉ cho phép kết nối từ **EC2 instances** (App Security Group)
- Database **không thể truy cập trực tiếp** từ internet

## Cách 1: SSH Tunnel (Khuyến nghị - An toàn nhất)

### Bước 1: Lấy thông tin cần thiết

Sau khi chạy `terraform apply`, lấy thông tin từ outputs:

```bash
terraform output
```

Bạn cần:
- **EC2 Public IP**: Để SSH vào
- **RDS Endpoint**: Địa chỉ database (ví dụ: `xxx.rds.amazonaws.com`)
- **RDS Port**: 3306 (MySQL) hoặc 5432 (PostgreSQL)
- **Database Name**: Tên database
- **Username/Password**: Từ SSM Parameter Store

### Bước 2: Tạo SSH Tunnel

Mở terminal và chạy lệnh SSH tunnel:

**Cho MySQL:**
```bash
ssh -i /path/to/your-key.pem -L 3307:RDS_ENDPOINT:3306 ubuntu@EC2_PUBLIC_IP -N
```

**Cho PostgreSQL:**
```bash
ssh -i /path/to/your-key.pem -L 5433:RDS_ENDPOINT:5432 ubuntu@EC2_PUBLIC_IP -N
```

**Giải thích:**
- `-L 3307:RDS_ENDPOINT:3306`: Tạo tunnel từ local port 3307 → RDS endpoint port 3306
- `-N`: Không chạy command, chỉ forward port
- Thay `RDS_ENDPOINT` và `EC2_PUBLIC_IP` bằng giá trị thực tế

**Ví dụ:**
```bash
ssh -i ~/.ssh/my-key.pem -L 3307:mydb.abc123.us-east-1.rds.amazonaws.com:3306 ubuntu@54.123.45.67 -N
```

### Bước 3: Cấu hình Navicat

1. Mở Navicat và tạo connection mới:
   - **Connection Name**: Tên tùy ý (ví dụ: "My RDS via SSH")
   
2. Tab **General**:
   - **Host**: `127.0.0.1` hoặc `localhost`
   - **Port**: `3307` (cho MySQL) hoặc `5433` (cho PostgreSQL) - **port local bạn đã tạo tunnel**
   - **Username**: Database username
   - **Password**: Database password
   - **Database**: Database name

3. Tab **SSH Tunnel**:
   - ✅ **Use SSH Tunnel**: Bật
   - **Host**: EC2 Public IP
   - **Port**: `22`
   - **User Name**: `ubuntu`
   - **Authentication Method**: Public Key
   - **Private Key**: Chọn file `.pem` key của bạn

4. Click **Test Connection** để kiểm tra

### Bước 4: Kết nối

- Giữ terminal SSH tunnel đang chạy
- Click **Connect** trong Navicat

---

## Cách 2: Mở Security Group cho IP của bạn (Ít an toàn hơn)

Nếu bạn muốn kết nối trực tiếp mà không cần SSH tunnel, cần thêm rule vào RDS security group.

### Bước 1: Lấy IP public của bạn

```bash
curl ifconfig.me
```

Hoặc truy cập: https://whatismyipaddress.com/

### Bước 2: Thêm rule vào Security Group

Có 2 cách:

#### Cách A: Thêm vào Terraform (Đã được tích hợp sẵn)

Tính năng này đã được tích hợp sẵn! Chỉ cần thêm vào `environments/prod/us-east-1/terraform.tfvars`:

```hcl
projects = {
  myproject = {
    project_short    = "myapp"
    project_full     = "My Application"
    db_name          = "mydb"
    db_username      = "admin"
    password_ssm_param = "/myapp/prod/db/password"
    # ... other config ...
    rds_allowed_cidrs = ["YOUR_IP/32"]  # Ví dụ: ["123.45.67.89/32"]
  }
}
```

Sau đó chạy:
```bash
terraform plan
terraform apply
```

⚠️ **Lưu ý**: Chỉ thêm IP của bạn (dạng `/32`). Không dùng `0.0.0.0/0` vì không an toàn.

#### Cách B: Thêm trực tiếp qua AWS Console

1. Vào **EC2 Console** → **Security Groups**
2. Tìm security group của RDS (tên có `-sg-rds`)
3. Click **Edit inbound rules**
4. Thêm rule:
   - **Type**: MySQL/Aurora (port 3306) hoặc PostgreSQL (port 5432)
   - **Source**: Your IP/32 (ví dụ: `123.45.67.89/32`)
5. Save

### Bước 3: Cấu hình Navicat (Trực tiếp)

1. **Host**: RDS Endpoint (ví dụ: `mydb.abc123.us-east-1.rds.amazonaws.com`)
2. **Port**: 3306 (MySQL) hoặc 5432 (PostgreSQL)
3. **Username**: Database username
4. **Password**: Database password
5. **Database**: Database name

⚠️ **Lưu ý**: Cách này ít an toàn hơn vì expose database ra internet. Chỉ nên dùng cho development hoặc với IP cố định.

---

## Lấy thông tin Database từ Terraform Outputs

Sau khi deploy, chạy:

```bash
cd environments/prod/us-east-1
terraform output
```

Hoặc lấy thông tin cụ thể:

```bash
# RDS Endpoint
terraform output -json | jq '.projects.YOUR_PROJECT_KEY.value.rds_endpoint'

# RDS Port
terraform output -json | jq '.projects.YOUR_PROJECT_KEY.value.rds_port'

# EC2 Public IP
terraform output -json | jq '.projects.YOUR_PROJECT_KEY.value.ec2_public_ips[0]'
```

---

## Troubleshooting

### Lỗi: "Connection timeout"
- Kiểm tra SSH tunnel có đang chạy không
- Kiểm tra Security Group có cho phép kết nối từ EC2 không
- Kiểm tra RDS endpoint có đúng không

### Lỗi: "Access denied"
- Kiểm tra username/password
- Kiểm tra database name có đúng không
- Kiểm tra user có quyền truy cập database không

### Lỗi: "Can't connect to MySQL server"
- Đảm bảo RDS instance đã khởi động hoàn toàn
- Kiểm tra Security Group rules
- Kiểm tra RDS endpoint có đúng không

