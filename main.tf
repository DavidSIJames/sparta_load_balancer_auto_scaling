provider "aws"{
  region = "eu-west-1"
}

module "app"{
  source = "./modules/app_tier"
  vpc_id = "${aws_vpc.david_vpc.id}"
  gateway_id = "${aws_internet_gateway.david_gateway.id}"
  db_instance_id = "${aws_instance.david_db.id}"
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

resource "aws_subnet" "David_private_subnet" {
  vpc_id     = "${aws_vpc.david_vpc.id}"
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "David-private-subnet"
  }
}

resource "aws_route_table_association" "david_pri_rta" {
  subnet_id = "${aws_subnet.David_private_subnet.id}"
  route_table_id = "${module.app.route_table}"
}

resource "aws_security_group" "david_private_sg" {
  name        = "david-private-sg"
  description = "security group for davids private subnet"
  vpc_id      = "${aws_vpc.david_vpc.id}"

  ingress{
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags{
    Name = "david-private-sg"
  }
}

resource "aws_network_acl" "david_private_nacl" {
  vpc_id = "${aws_vpc.david_vpc.id}"
  subnet_ids = ["${aws_subnet.David_private_subnet.id}"]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 27017
    to_port    = 27017
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 27017
    to_port    = 27017
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 202
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "David-private-nacl"
  }
}
resource "aws_instance" "david_db" {
  ami           = "ami-065c39f8960c44baf"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.David_private_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.david_private_sg.id}"]
  key_name = "DevOpsStudents"
  tags {
    Name = "david-db"
  }
}
