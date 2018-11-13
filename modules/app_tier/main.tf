

data "template_file" "app_init"{
  template = "${file("./scripts/app/init.sh.tpl")}"

  vars{
  db_ip = "mongod://${var.db_instance_id}:27017/posts"
  }
}

resource "aws_subnet" "David_public_subnet" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "David-public-subnet"
  }
}
resource "aws_route_table" "david_route_table" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.gateway_id}"
  }

  tags {
    Name = "main"
  }
}

resource "aws_route_table_association" "david_pub_rta" {
  subnet_id = "${aws_subnet.David_public_subnet.id}"
  route_table_id = "${aws_route_table.david_route_table.id}"
}

resource "aws_security_group" "david_public_sg" {
  name        = "david-public-sg"
  description = "security group for davids public subnet"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags{
    Name = "david-public-sg"
  }
}

resource "aws_network_acl" "david_public_nacl" {
  vpc_id = "${var.vpc_id}"
  subnet_ids = ["${aws_subnet.David_public_subnet.id}"]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
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
    rule_no    = 201
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 27017
    to_port    = 27017
  }

  egress {
    protocol   = "tcp"
    rule_no    = 202
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags {
    Name = "David-public-nacl"
  }
}

resource "aws_instance" "david_app" {
  ami           = "ami-04652c544988c667d"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.David_public_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.david_public_sg.id}"]
  key_name = "DevOpsStudents"
  user_data = "${data.template_file.app_init.rendered}"
  tags {
    Name = "david-app"
  }
}
