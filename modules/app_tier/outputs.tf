output "subnet"{
  value = "${aws_subnet.David_public_subnet.id}"
}

output "route_table"{
  value = "${aws_route_table.david_route_table.id}"
}

output "security_group"{
  value = "${aws_security_group.david_public_sg.id}"
}

output "data"{
  value = "${data.template_file.app_init.rendered}"
}
