# Data sources for dynamic values

data "aws_availability_zones" "available" {
  state = "available"
}

# Use provided AZs or fallback to available AZs
locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
}

