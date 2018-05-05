provider "aws" {
  region = "${var.aws_region}"
}

locals {
  tfe_name = "${var.alias_name}-${var.env_type}"
}

# create the alb
module "alb" {
  source        = "alb/"
  alb_name      = "${var.alias_name}-${var.env_type}"
  pub_access_sg = "${var.pub_access_sg}"
  pub_subnets   = "${var.pub_subnets}"
  env_type      = "${var.env_type}"
}

# create the associated a record for the alb
module "dns" {
  source          = "dns/"
  alias_name      = "${var.alias_name}"
  target_r53_zone = "${var.target_r53_zone}"
  alb_dns_name    = "${module.alb.dns_name}"
  alb_zone_id     = "${module.alb.zone_id}"
}

# create the private sg
module "sg" {
  source                = "sg/"
  priv_sg_name          = "${local.tfe_name}-private-sg"
  priv_sg_desc          = "${var.alias_name} ${var.env_type} private sg"
  vpc_id                = "${var.priv_access_vpc_id}"
  sg_allow_inbound_from = "${var.sg_allow_inbound_from}"
  pub_access_sg         = "${var.pub_access_sg}"
}

# find the most recent centos spel ami
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

# create the instance
module "lx-instance" {
  source = "${var.template_source}"

  Name             = "${local.tfe_name}-lx-instance"
  AmiId            = "${data.aws_ami.centos7.image_id}"
  AmiDistro        = "CentOS"
  AppVolumeSize    = "40"
  AppScriptUrl     = "${var.appscript_url}"
  KeyPairName      = "${var.key_pair}"
  InstanceType     = "${var.instance_type}"
  InstanceRole     = "${var.instance_role}"
  NoPublicIp       = "false"
  SecurityGroupIds = "${module.sg.private_sg_id}"
  SubnetId         = "${var.priv_subnet}"
}

# crate the docker ebs volume
module "ebs" {
  source            = "ebs/"
  availability_zone = "us-east-1a"
  vol_size          = "40"
  vol_name          = "${local.tfe_name}"
  dev_name          = "/dev/xvdg"
  instance_id       = "${module.lx-instance.watchmaker-lx-instance-id}"
}
