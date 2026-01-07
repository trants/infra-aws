variable "name_prefix" {
  description = "Prefix for SG names, e.g. infra-prod-use1"
  type        = string
}

variable "purpose" {
  description = "Purpose of security group, e.g. api, rds, alb"
  type        = string
  default     = "app"
}

variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into EC2 (e.g. your public IP /32)"
  type        = list(string)
  default     = []
}

variable "allow_http_https_from_cidrs" {
  description = "CIDR blocks allowed to access HTTP/HTTPS (use 0.0.0.0/0 if no ALB yet)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rds_port" {
  description = "RDS database port (3306 for MySQL, 5432 for PostgreSQL, etc.)"
  type        = number
  default     = 3306
}

variable "rds_allowed_cidrs" {
  description = "CIDR blocks allowed to access RDS directly (for Navicat, etc.). Empty by default - only allows from App SG."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
