# ============================================================================
# PROJECT MODULE
# Creates EC2, RDS, and Security Groups for a single project
# ============================================================================

locals {
  name_prefix = "${var.project_short}-${var.environment}-${var.region_short}"
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

module "security_groups" {
  source = "../security-groups"

  name_prefix = local.name_prefix
  purpose     = var.ec2_purpose
  vpc_id      = var.vpc_id

  ssh_allowed_cidrs         = var.ssh_allowed_cidrs
  allow_http_https_from_cidrs = ["0.0.0.0/0"]

  tags = merge(var.base_tags, {
    Tier    = "app"
    Service = var.ec2_purpose
  })
}

# ============================================================================
# RDS
# ============================================================================

module "rds" {
  source = "../rds"

  name_prefix = local.name_prefix
  engine       = var.rds_engine
  role         = "primary"

  db_name            = var.db_name
  username           = var.db_username
  password_ssm_param  = var.password_ssm_param

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [module.security_groups.rds_sg_id]

  instance_class        = var.rds_instance_class
  backup_retention_days = 7

  tags = merge(var.base_tags, {
    Tier    = "data"
    Service = "database"
  })
}

# ============================================================================
# EC2 INSTANCES
# ============================================================================

module "ec2" {
  source   = "../ec2"
  for_each = { for idx in range(var.ec2_count) : idx => idx }

  name_prefix     = local.name_prefix
  purpose         = var.ec2_purpose
  instance_index  = each.value + 1 # Start from 1

  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.app_sg_id]

  instance_type    = var.ec2_instance_type
  root_volume_size = 30
  associate_eip    = true

  key_name  = var.ec2_key_name
  user_data = var.ec2_user_data

  tags = merge(var.base_tags, {
    Tier    = "app"
    Service = var.ec2_purpose
  })
}

