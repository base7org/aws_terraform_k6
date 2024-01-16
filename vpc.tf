# VPC

resource "aws_vpc" "site_vpc" {
  cidr_block           = var.site_vpc_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Public Subnet

resource "aws_subnet" "site_public_subnet" {
  count             = length(var.site_vpc_public_subnets) == length(var.site_vpc_public_subnets) ? 2 : 0
  vpc_id            = aws_vpc.site_vpc.id
  availability_zone = data.aws_availability_zones.site_azs.names[count.index]
  cidr_block        = element(var.site_vpc_public_subnets, count.index)
}

resource "aws_internet_gateway" "site_public_gateway" {
  vpc_id = aws_vpc.site_vpc.id
}

resource "aws_route_table" "site_public_route_table" {
  vpc_id = aws_vpc.site_vpc.id
}

resource "aws_route" "site_public_route" {
  route_table_id         = aws_route_table.site_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.site_public_gateway.id
}

resource "aws_route_table_association" "site_public_route_table_association" {
  count          = length(aws_subnet.site_public_subnet) == 2 ? 2 : 0
  route_table_id = aws_route_table.site_public_route_table.id
  subnet_id      = element(aws_subnet.site_public_subnet.*.id, count.index)
}

# Public Subnet

resource "aws_subnet" "site_private_subnet" {
  count             = length(var.site_vpc_private_subnets) == length(var.site_vpc_private_subnets) ? 2 : 0
  vpc_id            = aws_vpc.site_vpc.id
  availability_zone = data.aws_availability_zones.site_azs.names[count.index]
  cidr_block        = element(var.site_vpc_private_subnets, count.index)
}

resource "aws_internet_gateway" "site_private_gateway" {
  vpc_id = aws_vpc.site_vpc.id
}

resource "aws_route_table" "site_private_route_table" {
  vpc_id = aws_vpc.site_vpc.id
}

resource "aws_route" "site_private_route" {
  route_table_id         = aws_route_table.site_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.site_private_gateway.id
}

resource "aws_route_table_association" "site_private_route_table_association" {
  count          = length(aws_subnet.site_private_subnet) == 2 ? 2 : 0
  route_table_id = aws_route_table.site_private_route_table.id
  subnet_id      = element(aws_subnet.site_private_subnet.*.id, count.index)
}

# Cloudwatch

resource "aws_cloudwatch_log_group" "site_logs_vpc" {
  name              = "${var.site_name}-flow-logs"
  retention_in_days = 90
}

resource "aws_flow_log" "site_flow_log" {
  iam_role_arn         = aws_iam_role.site_role.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.site_logs_vpc.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.site_vpc.id
}

