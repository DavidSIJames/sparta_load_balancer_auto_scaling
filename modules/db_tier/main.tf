resource "aws_subnet" "David_private_subnet" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags {
    Name = "David-private-subnet"
  }
}

resource "aws_route_table_association" "david_pri_rta" {
  subnet_id = "${aws_subnet.David_private_subnet.id}"
  route_table_id = "${var.app_route_table}"
}

resource "aws_security_group" "david_private_sg" {
  name        = "david-private-sg"
  description = "security group for davids private subnet"
  vpc_id      = "${var.vpc_id}"

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
  vpc_id = "${var.vpc_id}"
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
