resource "aws_vpc" "site_vpc" {
  cidr_block           = var.site_vpc
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "site_public_subnet" {
  count             = var.site_vpc == "10.0.0.0/16" ? 2 : 0
  vpc_id            = aws_vpc.site_vpc.id
  availability_zone = data.aws_availability_zones.site_azs.names[count.index]
  cidr_block        = element(cidrsubnets(var.site_vpc, 8, 4, 4), count.index)
}

resource "aws_internet_gateway" "site_gateway" {
  vpc_id = aws_vpc.site_vpc.id
}

resource "aws_route_table" "site_route_table" {
  vpc_id = aws_vpc.site_vpc.id
}

resource "aws_route" "site_public_route" {
  route_table_id         = aws_route_table.site_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.site_gateway.id
}

resource "aws_route_table_association" "site_route_table_association" {
  count          = length(aws_subnet.site_public_subnet) == 2 ? 2 : 0
  route_table_id = aws_route_table.site_route_table.id
  subnet_id      = element(aws_subnet.site_public_subnet.*.id, count.index)
}

resource "aws_cloudwatch_log_group" "site_log-group" {
  name              = "${var.site_name}-flow-logs"
  retention_in_days = 90
}

resource "aws_flow_log" "site_flow-log" {
  iam_role_arn         = aws_iam_role.site_role.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.site_log-group.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.site_vpc.id
}

