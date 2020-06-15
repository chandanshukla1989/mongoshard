provider "aws" {
  region     = "${var.region}"
 
}
resource "aws_vpc" "production-vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
}
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = "${var.public_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.production-vpc.id}"
  availability_zone = "us-west-1a"
}
resource "aws_subnet" "public-subnet-2" {
  cidr_block        = "${var.public_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.production-vpc.id}"
  availability_zone = "us-west-1b"
}
resource "aws_subnet" "public-subnet-3" {
  cidr_block        = "${var.public_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.production-vpc.id}"
  availability_zone = "us-west-1b"
}
resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.production-vpc.id}"
}
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = "${aws_route_table.public-route-table.id}"
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
}
resource "aws_route_table_association" "public-route-2-association" {
  route_table_id = "${aws_route_table.public-route-table.id}"
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
}
resource "aws_route_table_association" "public-route-3-association" {
  route_table_id = "${aws_route_table.public-route-table.id}"
  subnet_id      = "${aws_subnet.public-subnet-3.id}"
}
resource "aws_subnet" "private-subnet-1" {
  cidr_block        = "${var.private_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.production-vpc.id}"
  availability_zone = "us-west-1a"
}
resource "aws_subnet" "private-subnet-2" {
  cidr_block        = "${var.private_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.production-vpc.id}"
  availability_zone = "us-west-1b"
}
resource "aws_subnet" "private-subnet-3" {
  cidr_block        = "${var.private_subnet_3_cidr}"
  vpc_id            = "${aws_vpc.production-vpc.id}"
  availability_zone = "us-west-1b"
}
resource "aws_route_table" "private-route-table" {
  vpc_id = "${aws_vpc.production-vpc.id}"
}

resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = "${aws_route_table.private-route-table.id}"
  subnet_id      = "${aws_subnet.private-subnet-1.id}"
}
resource "aws_route_table_association" "private-route-2-association" {
  route_table_id = "${aws_route_table.private-route-table.id}"
  subnet_id      = "${aws_subnet.private-subnet-2.id}"
}
resource "aws_route_table_association" "private-route-3-association" {
  route_table_id = "${aws_route_table.private-route-table.id}"
  subnet_id      = "${aws_subnet.private-subnet-3.id}"
}

resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"
}
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.elastic-ip-for-nat-gw.id}"
  subnet_id     = "${aws_subnet.public-subnet-1.id}"
  depends_on = ["aws_eip.elastic-ip-for-nat-gw"]
}
resource "aws_route" "nat-gw-route" {
  route_table_id         = "${aws_route_table.private-route-table.id}"
  nat_gateway_id         = "${aws_nat_gateway.nat-gw.id}"
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_internet_gateway" "production-igw" {
  vpc_id = "${aws_vpc.production-vpc.id}"
}
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = "${aws_route_table.public-route-table.id}"
  gateway_id             = "${aws_internet_gateway.production-igw.id}"
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_security_group" "sg_22" {
  name = "sg_22"
  vpc_id = "${aws_vpc.production-vpc.id}"
  ingress {
      from_port   = 22
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "ec2key" {
  key_name = "publicKey"
  public_key = "${file(var.public_key_path)}"
}
resource "aws_instance" "shard1" {
  count         = 3
  ami           = "${var.ami_machine}"
  instance_type = "${var.instancetype}"
  subnet_id = "${count.index%2==1 ? "${aws_subnet.private-subnet-1.id}":"${aws_subnet.private-subnet-2.id}"}"
  vpc_security_group_ids = ["${aws_security_group.sg_22.id}"]
  key_name = "${aws_key_pair.ec2key.key_name}"
  tags ={
Name = "shard1-replica${count.index + 1}"
}
}
resource "aws_instance" "shard2" {
  count         = 3
  ami           = "${var.ami_machine}"
  instance_type = "${var.instancetype}"
  subnet_id = "${count.index%2==1 ? "${aws_subnet.private-subnet-1.id}":"${aws_subnet.private-subnet-2.id}"}"
  vpc_security_group_ids = ["${aws_security_group.sg_22.id}"]
  key_name = "${aws_key_pair.ec2key.key_name}"
  tags ={
Name = "shard2-replica${count.index + 1}"
}
}
resource "aws_instance" "config" {
  count         = 3
  ami           = "${var.ami_machine}"
  instance_type = "${var.instancetype}"
  subnet_id = "${count.index%2==1 ? "${aws_subnet.private-subnet-1.id}":"${aws_subnet.private-subnet-2.id}"}"
  vpc_security_group_ids = ["${aws_security_group.sg_22.id}"]
  key_name = "${aws_key_pair.ec2key.key_name}"
  tags ={
Name = "config${count.index + 1}"
}
}
resource "aws_instance" "route" {
  count         = 3
  ami           = "${var.ami_machine}"
  instance_type = "${var.instancetype}"
  subnet_id = "${count.index%2==1 ? "${aws_subnet.private-subnet-1.id}":"${aws_subnet.private-subnet-2.id}"}"
  vpc_security_group_ids = ["${aws_security_group.sg_22.id}"]
  key_name = "${aws_key_pair.ec2key.key_name}"
  tags ={
Name = "router${count.index + 1}"
}
}


output "config_addresses1" {
  value = {
    for instance in aws_instance.config:
#      instance.id => instance.private_ip
      instance.tags.Name => instance.private_ip
  }
}
output "router_addresses1" {
  value = {
    for instance in aws_instance.route:
#      instance.id => instance.private_ip
      instance.tags.Name => instance.private_ip
  }
}
output "shard1_addresses" {
  value = {
    for instance in aws_instance.shard1:
#      instance.id => instance.private_ip
       "${instance.private_ip} ${instance.private_dns} ${instance.tags.Name}" => instance.public_ip
  }
}
output "shard2_addresses" {
  value = {
    for instance in aws_instance.shard2:
#      instance.id => instance.private_ip
       "${instance.private_ip} ${instance.private_dns} ${instance.tags.Name}" => instance.public_ip
  }
}
output "config_addresses" {
  value = {
    for instance in aws_instance.config:
#      instance.id => instance.private_ip
       "${instance.private_ip} ${instance.private_dns} ${instance.tags.Name}" => instance.public_ip
  }
}
output "router_addresses" {
  value = {
    for instance in aws_instance.route:
#      instance.id => instance.private_ip
       "${instance.private_ip} ${instance.private_dns} ${instance.tags.Name}" => instance.public_ip
  }
}
