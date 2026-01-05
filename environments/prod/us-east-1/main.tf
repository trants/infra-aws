locals {
  region_short = "use1"

  base_tags = {
    Environment = var.environment
    Region      = var.aws_region
    Project     = var.project
    ManagedBy   = "terraform"
  }

  vpc_name = "${var.environment}-${local.region_short}-vpc"
}

module "vpc" {
  source = "../../../modules/vpc"

  name = local.vpc_name
  cidr = "10.0.0.0/16"

  azs = [
    "us-east-1a",
    "us-east-1b",
  ]

  public_subnet_cidrs = [
    "10.0.0.0/24",
    "10.0.1.0/24",
  ]

  private_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.11.0/24",
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.base_tags
}

module "security_groups" {
  source = "../../../modules/security-groups"

  name_prefix = "${var.environment}-${local.region_short}"
  vpc_id      = module.vpc.vpc_id

  # SSH: chỉ cho IP của bạn (khuyến nghị set /32)
  # Ví dụ: ["203.0.113.10/32"]
  ssh_allowed_cidrs = var.ssh_allowed_cidrs

  # Nếu chưa có ALB, tạm thời để 0.0.0.0/0 cho 80/443
  allow_http_https_from_cidrs = ["0.0.0.0/0"]

  tags = local.base_tags
}

module "rds" {
  source = "../../../modules/rds"

  name_prefix = "${var.environment}-${local.region_short}"

  db_name  = "app_db"
  username = "app_user"

  password_ssm_param = "/infra-aws/prod/mysql/password"

  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.security_groups.rds_sg_id]

  instance_class        = "db.t3.micro"
  backup_retention_days = 7

  tags = local.base_tags
}

module "ec2" {
  source = "../../../modules/ec2"

  name_prefix = "${var.environment}-${local.region_short}"

  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.app_sg_id]

  instance_type     = "t3.small"
  root_volume_size  = 30
  associate_eip     = true

  key_name  = var.ec2_key_name
  user_data = file("${path.module}/user_data_app.sh")

  tags = local.base_tags
}
