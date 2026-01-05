variable "name_prefix" {
  description = "Prefix for EC2 resources, e.g. infra-prod-use1"
  type        = string
}

variable "purpose" {
  description = "Purpose of EC2 instance, e.g. api, web, worker"
  type        = string
  default     = "app"
}

variable "instance_index" {
  description = "Instance index for multiple instances (1, 2, ...) - will be formatted as 01, 02"
  type        = number
  default     = 1
}

variable "subnet_id" { type = string }
variable "vpc_security_group_ids" { type = list(string) }

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH"
  type        = string
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "associate_eip" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "user_data" {
  description = "Cloud-init user_data to install docker/compose and start services"
  type        = string
  default     = ""
}
