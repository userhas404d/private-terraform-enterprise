variable "aws_region" {}
variable "env_type" {}

variable "alias_name" {}
variable "target_r53_zone" {}

variable "pub_access_sg" {}
variable "pub_access_vpc_id" {}

variable "pub_subnets" {
  type = "list"
}

variable "priv_access_vpc_id" {}
variable "sg_allow_inbound_from" {}

# lx-instance
variable "ami_id" {}
variable "instance_role" {}
variable "key_pair" {}
variable "priv_subnet" {}
