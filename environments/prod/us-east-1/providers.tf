terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }

  backend "s3" {
    # Backend configuration - set via backend config file or CLI
    # Example: terraform init -backend-config=backend.hcl
    # Or use environment variables: TF_BACKEND_BUCKET, TF_BACKEND_KEY, etc.
    # bucket         = "terraform-state-${var.aws_region}"
    # key            = "prod/us-east-1/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-state-lock"
    # encrypt        = true
    # kms_key_id     = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID" # Optional
  }
}

provider "aws" {
  region = var.aws_region

  # Optional: Uncomment if using cross-account or assume role
  # assume_role {
  #   role_arn = var.aws_assume_role_arn
  # }

  # Optional: Uncomment if using AWS profiles
  # profile = var.aws_profile

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project
    }
  }
}
