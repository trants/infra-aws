# Project identification
variable "project_key" {
  description = "Key/identifier for this project (used in for_each)"
  type        = string
}

variable "project_short" {
  description = "Short project identifier (3-8 chars, lowercase) for resource naming"
  type        = string
}

variable "project_full" {
  description = "Full project name (for tags)"
  type        = string
}

variable "environment" {
  description = "Environment: dev, staging, prod"
  type        = string
}

variable "region_short" {
  description = "Short region code, e.g. use1"
  type        = string
}

# VPC configuration (shared)
variable "vpc_id" {
  description = "VPC ID (shared across projects)"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# EC2 configuration
variable "ec2_purpose" {
  description = "Purpose of EC2 instance, e.g. api, web, worker"
  type        = string
  default     = "api"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ec2_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "ec2_key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "ec2_user_data" {
  description = "User data script for EC2"
  type        = string
  default     = ""
}

variable "ec2_root_volume_size" {
  description = "Root volume size in GB for EC2 instances"
  type        = number
  default     = 30
}

variable "ec2_associate_eip" {
  description = "Whether to associate Elastic IP with EC2 instances"
  type        = bool
  default     = true
}

variable "ec2_iam_instance_profile" {
  description = "IAM instance profile name or ARN for EC2 instances"
  type        = string
  default     = ""
}

# RDS configuration
variable "rds_engine" {
  description = "Database engine: mysql, postgres, mariadb"
  type        = string
  default     = "mysql"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "password_ssm_param" {
  description = "SSM parameter path for database password"
  type        = string
}

variable "rds_backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "rds_apply_immediately" {
  description = "Apply RDS changes immediately (false = use maintenance window)"
  type        = bool
  default     = false
}

variable "rds_port" {
  description = "RDS database port (3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
  default     = 3306
}

variable "allow_http_https_from_cidrs" {
  description = "CIDR blocks allowed to access HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Security
variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = []
}

# Tags
variable "base_tags" {
  description = "Base tags to apply to all resources"
  type        = map(string)
  default     = {}
}

