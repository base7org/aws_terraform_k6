resource "aws_lb_target_group" "site_target_group" {
  name        = "${var.site_name}-target-group"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.site_vpc.id
}

resource "aws_alb_target_group_attachment" "site_target_attachment" {
  count            = length(aws_instance.site_instance.*.id) == 2 ? 2 : 0
  target_group_arn = aws_lb_target_group.site_target_group.arn
  target_id        = element(aws_instance.site_instance.*.id, count.index)
}

resource "aws_lb" "site_lb" {
  name               = "${var.site_name}-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.site_sg.id, ]
  subnets            = aws_subnet.site_public_subnet.*.id
}

resource "aws_lb_listener" "site_http" {
  load_balancer_arn = aws_lb.site_lb.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_target_group.site_target_group]
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "site_https" {
  load_balancer_arn = aws_lb.site_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.site_certificate.arn
  depends_on        = [aws_lb_target_group.site_target_group, aws_acm_certificate.site_certificate]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.site_target_group.arn
  }
}

resource "aws_route53_record" "site_lb-domain_record" {
  zone_id = aws_route53_zone.site_zone.zone_id
  name    = var.site_domain
  type    = "A"
  alias {
    name                   = aws_lb.site_lb.dns_name
    zone_id                = aws_lb.site_lb.zone_id
    evaluate_target_health = true
  }
}