output "db_instance_ip"{
  value = "${aws_instance.david_db.private_ip}"
}
