output "project_key" {
  description = "Project key/identifier"
  value       = var.project_key
}

output "name_prefix" {
  description = "Name prefix for this project"
  value       = "${var.project_short}-${var.environment}-${var.region_short}"
}

# Security Groups
output "app_sg_id" {
  description = "App security group ID"
  value       = module.security_groups.app_sg_id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = module.security_groups.rds_sg_id
}

# RDS
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

output "rds_db_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}

# EC2
output "ec2_instances" {
  description = "Map of EC2 instances (key = instance_index, value = instance details)"
  value = {
    for k, v in module.ec2 : k => {
      instance_id = v.instance_id
      public_ip   = v.public_ip
      eip_public_ip = v.eip_public_ip
    }
  }
}

output "ec2_instance_ids" {
  description = "List of EC2 instance IDs"
  value       = [for k, v in module.ec2 : v.instance_id]
}

output "ec2_public_ips" {
  description = "List of EC2 public IPs"
  value       = [for k, v in module.ec2 : v.eip_public_ip != null ? v.eip_public_ip : v.public_ip]
}

