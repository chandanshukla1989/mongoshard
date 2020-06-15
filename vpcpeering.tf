resource "aws_vpc_peering_connection" "sourcedefault" {
  peer_vpc_id   = "${aws_vpc.destination.id}"
  vpc_id        = "${aws_vpc.sourcedefault.id}"
  auto_accept   = true


  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}
resource "aws_vpc" "sourcedefault" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_vpc" "destination" {
  cidr_block = "10.0.0.0/16"
}
