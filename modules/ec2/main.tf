data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = var.user_data != "" ? var.user_data : null

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ec2-app"
    Service = "shared"
    Tier    = "app"
  })
}

resource "aws_eip" "this" {
  count  = var.associate_eip ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-eip-app"
    Service = "shared"
    Tier    = "app"
  })
}

resource "aws_eip_association" "this" {
  count         = var.associate_eip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}
