variable "name_prefix" {
  description = "Prefix for RDS resources, e.g. infra-prod-use1"
  type        = string
}

variable "engine" {
  description = "Database engine: mysql, postgres, mariadb"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "" # Will use default if not specified
}

variable "role" {
  description = "Database role: primary, replica, read-replica"
  type        = string
  default     = "primary"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "username" {
  description = "Master DB username"
  type        = string
}

variable "password_ssm_param" {
  description = "SSM parameter name storing DB password (SecureString)"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "apply_immediately" {
  description = "Apply changes immediately (false = use maintenance window)"
  type        = bool
  default     = false
}

variable "backup_window" {
  description = "Preferred backup window (UTC). Format: hh24:mi-hh24:mi"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC). Format: ddd:hh24:mi-ddd:hh24:mi"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 60, 300)"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring (required if monitoring_interval > 0)"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
