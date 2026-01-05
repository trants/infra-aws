# App SG: for EC2/ALB targets
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-sg-${var.purpose}"
  description = "Security group for ${var.purpose} (HTTP/HTTPS + restricted SSH)"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-sg-${var.purpose}"
    Service = var.purpose
  })
}

# HTTP
resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = var.allow_http_https_from_cidrs[0]
}

# HTTPS
resource "aws_vpc_security_group_ingress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.allow_http_https_from_cidrs[0]
}

# Optional SSH (only if ssh_allowed_cidrs provided)
resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  count             = length(var.ssh_allowed_cidrs) > 0 ? length(var.ssh_allowed_cidrs) : 0
  security_group_id = aws_security_group.app.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidrs[count.index]
}

# Allow all outbound (typical for app SG)
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS SG: only allow MySQL from App SG
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-sg-rds"
  description = "RDS security group (MySQL only from app SG)"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-sg-rds"
    Service = "database"
    Tier    = "data"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_app" {
  security_group_id            = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
