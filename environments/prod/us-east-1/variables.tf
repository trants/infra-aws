variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
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
  default     = "prod"
  description = "Environment: dev, staging, prod"
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
