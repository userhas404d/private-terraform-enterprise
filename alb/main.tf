#------------------------------------------------------------------------------
# load balancing
#------------------------------------------------------------------------------

resource "aws_lb" "public" {
  name               = "${var.alb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.pub_access_sg}"]
  subnets            = ["${var.pub_subnets}"]

  enable_deletion_protection = false

  tags {
    Environment = "${var.env_type}"
  }
}

# nothing attached to this target group
resource "aws_lb_target_group" "blackhole" {
  name     = "blackhole"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${var.aws_lb_target_group_vpc}"
}

# forward requests for url with /admin to black hole
resource "aws_lb_listener_rule" "blackhole" {
  listener_arn = "${aws_lb_listener.frontend_https.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.blackhole.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/admin*"]
  }
}

resource "aws_lb_target_group" "tfe_https" {
  name     = "${var.https_target_group_name}"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "${var.aws_lb_target_group_vpc}"
}

resource "aws_lb_target_group_attachment" "tfe_https" {
  target_group_arn = "${aws_lb_target_group.tfe_https.arn}"
  target_id        = "${var.target_instance_id}"
  port             = 443
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = "${aws_lb.public.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"
  ssl_policy        = "ELBSecurityPolicy-2015-05"

  default_action {
    target_group_arn = "${aws_lb_target_group.tfe_https.arn}"
    type             = "forward"
  }
}

# create the certs

resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.domain_name}"
  validation_method = "DNS"

  tags {
    Environment = "${var.env_type}"
  }
}

# dns validation

resource "aws_route53_record" "cert_validation" {
  name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.r53_zone_id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}

resource "aws_lb_listener_certificate" "https_listener" {
  listener_arn    = "${aws_lb_listener.frontend_https.arn}"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
}
