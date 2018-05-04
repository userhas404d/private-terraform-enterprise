provider "aws" {
  region = "${var.aws_region}"
}

locals {
  tfe_name = "${var.alias_name}-${var.env_type}"
}

module "alb" {
  source        = "alb/"
  alb_name      = "${var.alias_name}-${var.env_type}"
  pub_access_sg = "${var.pub_access_sg}"
  pub_subnets   = "${var.pub_subnets}"
  env_type      = "${var.env_type}"
}

module "dns" {
  source          = "dns/"
  alias_name      = "${var.alias_name}"
  target_r53_zone = "${var.target_r53_zone}"
  alb_dns_name    = "${module.alb.dns_name}"
  alb_zone_id     = "${module.alb.zone_id}"
}

module "sg" {
  source                = "sg/"
  priv_sg_name          = "${local.tfe_name}-private-sg"
  priv_sg_desc          = "${var.alias_name} ${var.env_type} private sg"
  vpc_id                = "${var.priv_access_vpc_id}"
  sg_allow_inbound_from = "${var.sg_allow_inbound_from}"
  pub_access_sg         = "${var.pub_access_sg}"
}

data "aws_ami" "centos7" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*spel-minimal-centos-7*"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "owner-id"
    values = ["701759196663"]
  }
}

module "lx-instance" {
  source = "git::https://github.com/plus3it/terraform-aws-watchmaker//modules/lx-instance/"

  Name             = "${local.tfe_name}-lx-instance"
  AmiId            = "${data.aws_ami.centos7.image_id}"
  AmiDistro        = "CentOS"
  AppVolumeDevice  = "true"
  AppVolumeSize    = "40"
  AppScriptUrl     = "${var.appscript_url}"
  KeyPairName      = "${var.key_pair}"
  InstanceType     = "t2.large"
  InstanceRole     = "${var.instance_role}"
  NoPublicIp       = "false"
  SecurityGroupIds = "${module.sg.private_sg_id}"
  SubnetId         = "${var.priv_subnet}"
}
