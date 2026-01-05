data "aws_ssm_parameter" "db_password" {
  name            = var.password_ssm_param
  with_decryption = true
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
    Tier = "data"
  })
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name_prefix}-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.username
  password                = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids

  multi_az                = var.multi_az
  publicly_accessible     = false

  backup_retention_period = var.backup_retention_days
  skip_final_snapshot     = false
  deletion_protection     = true

  storage_encrypted       = true
  apply_immediately       = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-mysql"
    Tier = "data"
  })
}
