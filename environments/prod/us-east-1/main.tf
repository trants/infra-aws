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
