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

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "${var.ebs_dev_name}"
    volume_type           = "gp2"
    volume_size           = "${var.ebs_dev_size}"
    delete_on_termination = true
  }

  tags {
    Name = "${var.instance_name}"

    // CLAP_OFF = "0 19 * * 1-7 *"
    // CLAP_ON = ""
  }
}

output "instance_id" {
  description = "tfe instance id"
  value       = "${aws_instance.tfe_instance.id}"
}
