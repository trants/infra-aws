terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }

  backend "s3" {
    # Configure via backend.hcl or env vars (TF_BACKEND_BUCKET, etc.)
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

  # Uncomment for cross-account access or assume role
  # assume_role {
  #   role_arn = var.aws_assume_role_arn
  # }

  # Uncomment to use AWS profile
  # profile = var.aws_profile

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Project     = var.project
    }
  }
}
