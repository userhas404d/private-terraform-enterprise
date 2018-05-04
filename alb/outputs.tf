output "dns_name" {
  value = "${aws_lb.public.dns_name}"
}

output "zone_id" {
  value = "${aws_lb.public.zone_id}"
}
