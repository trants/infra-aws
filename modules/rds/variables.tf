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

variable "tags" {
  type    = map(string)
  default = {}
}
