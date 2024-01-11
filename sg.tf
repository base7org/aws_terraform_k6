locals {
  sg_rules = [{
    name        = "HTTPS"
    port        = 443
    description = "HTTPS rules."
    },
    {
      name        = "HTTP"
      port        = 80
      description = "HTTP rules."
    },
    {
      name        = "SSH"
      port        = 22
      description = "SSH rules."
  }]
}

resource "aws_security_group" "site_sg" {
  name        = "${var.site_name}-sg"
  description = "Traffic rules for ${var.site_name}"
  vpc_id      = aws_vpc.site_vpc.id
  egress = [
    {
      description      = "Outgoing traffic."
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  dynamic "ingress" {
    for_each = local.sg_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}