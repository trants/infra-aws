locals {
  # Region short code mapping
  region_short_map = {
    us-east-1      = "use1"
    us-west-2      = "usw2"
    eu-west-1      = "euw1"
    ap-southeast-1 = "apse1"
  }

  region_short = lookup(local.region_short_map, var.aws_region, replace(var.aws_region, "/-|_/", ""))

  # VPC name
  vpc_name = "${var.project}-${var.environment}-${local.region_short}-vpc"

  # Standard tags (required for billing, monitoring, compliance)
  base_tags = {
    Project     = var.project
    Environment = var.environment
    Region      = var.aws_region
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
    Owner       = var.owner
  }
}

# ============================================================================
# SHARED VPC (used by all projects)
# ============================================================================

module "vpc" {
  source = "../../../modules/vpc"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs = local.azs

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = merge(local.base_tags, {
    Name = local.vpc_name
    Type = "shared"
  })
}

# ============================================================================
# PROJECTS (each project has EC2 and RDS)
# ============================================================================

module "projects" {
  source   = "../../../modules/project"
  for_each = var.projects

  # Project configuration
  project_key     = each.key
  project_short   = each.value.project_short
  project_full    = each.value.project_full != "" ? each.value.project_full : each.value.project_short
  environment     = var.environment
  region_short    = local.region_short

  # VPC configuration (shared)
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids

  # EC2 configuration
  ec2_purpose       = each.value.ec2_purpose
  ec2_instance_type = each.value.ec2_instance_type
  ec2_count         = each.value.ec2_count
  ec2_key_name      = var.ec2_key_name
  ec2_user_data     = file("${path.module}/user-data.sh")

  # RDS configuration
  rds_engine         = each.value.rds_engine
  rds_instance_class = each.value.rds_instance_class
  db_name            = each.value.db_name
  db_username        = each.value.db_username
  password_ssm_param = each.value.password_ssm_param

  # Security
  ssh_allowed_cidrs = length(each.value.ssh_allowed_cidrs) > 0 ? each.value.ssh_allowed_cidrs : var.ssh_allowed_cidrs

  # Tags
  base_tags = merge(local.base_tags, {
    Project = each.value.project_full != "" ? each.value.project_full : each.value.project_short
  })
}
