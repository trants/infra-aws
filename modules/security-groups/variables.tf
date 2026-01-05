variable "name_prefix" {
  description = "Prefix for SG names, e.g. prod-use1"
  type        = string
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

variable "tags" {
  type    = map(string)
  default = {}
}
