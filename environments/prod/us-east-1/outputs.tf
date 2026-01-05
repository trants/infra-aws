output "app_sg_id" {
  value = module.security_groups.app_sg_id
}

output "rds_sg_id" {
  value = module.security_groups.rds_sg_id
}

output "app_instance_id" {
  value = module.ec2.instance_id
}

output "app_eip_public_ip" {
  value = module.ec2.eip_public_ip
}
