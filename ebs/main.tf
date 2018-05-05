resource "aws_ebs_volume" "docker_vol" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.vol_size}"
  type              = "${var.vol_type}"

  tags {
    Name = "${var.vol_name}"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "${var.dev_name}"
  volume_id   = "${aws_ebs_volume.docker_vol.id}"
  instance_id = "${var.instance_id}"
}
