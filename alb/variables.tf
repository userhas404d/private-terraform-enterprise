variable "alb_name" {}
variable "env_type" {}
variable "pub_access_sg" {}

variable "pub_subnets" {
  type = "list"
}

variable "https_target_group_name" {}
variable "config_target_group_name" {}
variable "aws_lb_target_group_vpc" {}
variable "target_instance_id" {}
variable "r53_zone_id" {}
variable "domain_name" {}
