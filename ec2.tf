resource "aws_instance" "site_instance" {
  count                = length(aws_subnet.site_public_subnet.*.id)
  ami                  = var.site_ami
  instance_type        = var.site_instance_size
  subnet_id            = element(aws_subnet.site_public_subnet.*.id, count.index)
  security_groups      = [aws_security_group.site_sg.id, ]
  iam_instance_profile = aws_iam_instance_profile.site_profile.name
  timeouts {
    create = "10m"
  }

  user_data = <<-EOL
  #!/bin/bash -xe

  yum update -y
  yum install httpd -y
  systemctl start httpd
  systemctl enable httpd
  echo 'Has anyone really been far even as decided to use even go want to do look more like?' >> /var/www/html/index.html
  EOL

}

resource "aws_eip" "site_elastic-ip" {
  count            = length(aws_instance.site_instance.*.id)
  instance         = element(aws_instance.site_instance.*.id, count.index)
  public_ipv4_pool = "amazon"
  vpc              = true
}

resource "aws_eip_association" "site_elastic-ip_association" {
  count         = length(aws_eip.site_elastic-ip)
  instance_id   = element(aws_instance.site_instance.*.id, count.index)
  allocation_id = element(aws_eip.site_elastic-ip.*.id, count.index)
}
