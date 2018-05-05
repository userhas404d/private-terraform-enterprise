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
