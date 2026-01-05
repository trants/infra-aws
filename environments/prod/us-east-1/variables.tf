variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "infra-aws"
}

variable "environment" {
  type    = string
  default = "prod"
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
