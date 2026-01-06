data "aws_ssm_parameter" "db_password" {
  name            = var.password_ssm_param
  with_decryption = true
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-rds-${var.engine}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-${var.engine}-subnet-group"
    Tier = "data"
  })
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-rds-${var.engine}-${var.role}"

  engine         = var.engine
  engine_version = var.engine_version != "" ? var.engine_version : (var.engine == "mysql" ? "8.0" : var.engine == "postgres" ? "15.4" : "10.11")

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.username
  password          = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period = var.backup_retention_days
  skip_final_snapshot    = false
  deletion_protection     = true

  storage_encrypted = true
  apply_immediately = var.apply_immediately

  # Backup and maintenance windows
  backup_window      = var.backup_window
  maintenance_window = var.maintenance_window

  # Performance Insights (optional)
  performance_insights_enabled = var.performance_insights_enabled

  # Monitoring
  monitoring_interval = var.monitoring_interval > 0 ? var.monitoring_interval : null
  monitoring_role_arn = var.monitoring_interval > 0 && var.monitoring_role_arn != "" ? var.monitoring_role_arn : null

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-${var.engine}-${var.role}"
    Tier = "data"
  })
}
