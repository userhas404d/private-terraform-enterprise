data "template_file" "init" {
  template = "${file("${path.module}/init.sh")}"
}

resource "aws_instance" "tfe_instance" {
  ami                    = "${var.ami_id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  subnet_id              = "${var.subnet_id}"
  iam_instance_profile   = "${var.instance_role}"
  user_data              = "${data.template_file.init.rendered}"

  tags {
    Name = "${var.instance_name}"
  }
}

output "instance_id" {
  description = "tfe instance id"
  value       = "${aws_instance.tfe_instance.id}"
}
