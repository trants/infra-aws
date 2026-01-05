# ============================================================================
# VPC OUTPUTS
# ============================================================================

output "vpc_id" {
  description = "Shared VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "Shared VPC name"
  value       = module.vpc.vpc_id # You can add vpc_name output to VPC module if needed
}

# ============================================================================
# PROJECTS OUTPUTS
# ============================================================================

output "projects" {
  description = "Map of all projects with their resources"
  value = {
    for project_key, project in module.projects : project_key => {
      name_prefix      = project.name_prefix
      app_sg_id        = project.app_sg_id
      rds_sg_id        = project.rds_sg_id
      rds_endpoint     = project.rds_endpoint
      rds_port         = project.rds_port
      rds_db_name      = project.rds_db_name
      ec2_instances    = project.ec2_instances
      ec2_instance_ids = project.ec2_instance_ids
      ec2_public_ips   = project.ec2_public_ips
    }
  }
}

# Convenience outputs for first project (if exists)
output "first_project" {
  description = "Resources of the first project (for backward compatibility)"
  value = length(module.projects) > 0 ? {
    for k, v in module.projects : k => v
  }[keys(module.projects)[0]] : null
}

