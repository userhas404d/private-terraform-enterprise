# generalg
variable "aws_region" {}

variable "env_type" {
  description = "test, dev, prod"
}

# DNS
variable "alias_name" {
  description = "A record that the TFE instance will be accessible from"
}

variable "target_r53_zone" {
  description = "target zone to add the TFE instance's alias to"
}

# networking
variable "pub_access_sg" {
  description = "id of the public access securitygroup"
}

variable "pub_access_vpc_id" {
  description = "id of the public access vpc"
}

variable "pub_subnets" {
  description = "list of publicly accessible subnets."
  type        = "list"
}

variable "priv_access_vpc_id" {
  description = "vpc id of a private (internal access only) vpc"
}

variable "sg_allow_inbound_from" {
  description = "id of the securitygroup to allow access from"
}

# instance
variable "ami_id" {}

variable "instance_role" {}

variable "instance_type" {
  default = "t2.large"
}

variable "key_pair" {}
variable "priv_subnet" {}
variable "appscript_url" {}

variable "template_file" {
  default = "./init.tpl"
}

# docker ebs volume
variable "ebs_dev_name" {
  default     = "/dev/xvdg"
  description = "block storage device name"
}
