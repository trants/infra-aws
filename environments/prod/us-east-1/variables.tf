variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "project" {
  type        = string
  default     = "infra-aws"
  description = "Full project name (for shared resources like VPC)"
}

variable "projects" {
  type = map(object({
    project_short    = string
    project_full     = optional(string, "")
    ec2_purpose      = optional(string, "api")
    ec2_instance_type = optional(string, "t3.small")
    ec2_count        = optional(number, 1)
    rds_engine       = optional(string, "mysql")
    rds_instance_class = optional(string, "db.t3.micro")
    db_name          = string
    db_username      = string
    password_ssm_param = string
    ssh_allowed_cidrs = optional(list(string), [])
  }))
  description = "Map of projects to create. Each project will have EC2 and RDS."
  default     = {}
}

variable "environment" {
  type        = string
  description = "Environment: dev, staging, prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "Your public IP in CIDR format for SSH, e.g. 1.2.3.4/32"
}

variable "ec2_key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "cost_center" {
  type        = string
  default     = "engineering"
  description = "Cost center for billing allocation"
}

variable "owner" {
  type        = string
  default     = "platform-team"
  description = "Team/owner responsible for this infrastructure"
}

# VPC configuration
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "List of availability zones. If empty, auto-detects available AZs"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per AZ)"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per AZ)"
}

# Optional AWS provider configuration
variable "aws_profile" {
  type        = string
  default     = ""
  description = "AWS profile to use (optional)"
}

variable "aws_assume_role_arn" {
  type        = string
  default     = ""
  description = "IAM role ARN to assume for cross-account access (optional)"
}
