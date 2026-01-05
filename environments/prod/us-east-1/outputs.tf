output "app_sg_id" {
  value = module.security_groups.app_sg_id
}

output "rds_sg_id" {
  value = module.security_groups.rds_sg_id
}
