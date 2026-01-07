data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  associate_public_ip_address = true

  user_data = var.user_data != "" ? var.user_data : null

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  # Enable detailed monitoring (optional, costs extra)
  monitoring = var.enable_detailed_monitoring

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-instance-${var.purpose}-${format("%02d", var.instance_index)}"
    Service = var.purpose
    Tier    = "app"
  })
}

resource "aws_eip" "this" {
  count  = var.associate_eip ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-eip-${var.purpose}-${format("%02d", var.instance_index)}"
    Service = var.purpose
    Tier    = "app"
  })
}

resource "aws_eip_association" "this" {
  count         = var.associate_eip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}
