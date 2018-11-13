provider "aws"{
  region = "eu-west-1"
}

module "app"{
  source = "./modules/app_tier"
  vpc_id = "${aws_vpc.david_vpc.id}"
  gateway_id = "${aws_internet_gateway.david_gateway.id}"
  db_instance_ip = "${module.db.db_instance_ip}"
}

module "db"{
  source = "./modules/db_tier"
  app_route_table = "${module.app.route_table}"
  vpc_id = "${aws_vpc.david_vpc.id}"
}

resource "aws_vpc" "david_vpc"{
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags{
    Name = "David-vpc"
  }
}

resource "aws_internet_gateway" "david_gateway" {
  vpc_id = "${aws_vpc.david_vpc.id}"

  tags {
    Name = "david-gateway"
  }
}

resource "aws_lb" "david_lb" {
  name               = "david-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${module.app.subnet}"]

  enable_deletion_protection = true

  tags {
    Name = "david_lb"
  }
}

resource "aws_launch_configuration" "david_launch_conf" {
  name_prefix   = "david-auto-instance-"
  image_id      = "ami-04652c544988c667d"
  instance_type = "t2.micro"
  user_data = "${module.app.data}"
  security_groups = ["${module.app.security_group}"]
  associate_public_ip_address = true
  key_name = "DevOpsStudents"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "david_auto_group" {
  name                 = "david-auto-group-terra"
  launch_configuration = "${aws_launch_configuration.david_launch_conf.name}"
  min_size             = 1
  max_size             = 3
  vpc_zone_identifier = ["${module.app.subnet}"]

  tags{
    key = "Name"
    value ="david-app-${count.index + 1}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
