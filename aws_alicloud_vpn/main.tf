# Region1(AWS)'s Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region1}"
}

# Region2(Alicloud)'s Provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region2}"
}

# AWS
resource "aws_vpc" "vpc1" {
  cidr_block = "172.16.0.0/16"

  tags {
    Name = "vpc1"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  cidr_block = "172.16.1.0/24"
  availability_zone = "${var.zone1}"

  tags {
    Name = "subnet1"
  }
}

resource "aws_vpn_gateway" "vgw1" {
  vpc_id = "${aws_vpc.vpc1.id}"

  tags {
    Name = "vgw1"
  }
}

resource "aws_customer_gateway" "vgw1_cgw1" {
  ip_address = "${alicloud_vpn_gateway.vgw2.internet_ip}"
  bgp_asn = 65000
  type = "ipsec.1"

  tags {
    Name = "vgw1_cgw1"
  }
  depends_on = ["alicloud_vpn_gateway.vgw2"]
}

resource "aws_vpn_connection" "ipsec1" {
  vpn_gateway_id = "${aws_vpn_gateway.vgw1.id}"
  customer_gateway_id = "${aws_customer_gateway.vgw1_cgw1.id}"
  type = "ipsec.1"
  static_routes_only = true
  
  tunnel1_preshared_key = "aws_alicloud"
  tunnel2_preshared_key = "aws_alicloud"

  tags {
    Name = "ipsec1"
  }
}

resource "aws_route_table" "route1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  propagating_vgws = ["${aws_vpn_gateway.vgw1.id}"]
  route {
    cidr_block = "${alicloud_vswitch.vsw2.cidr_block}"
    gateway_id = "${aws_vpn_gateway.vgw1.id}"
  }
  tags {
    Name = "route1"
  }
}

resource "aws_vpn_connection_route" "remote_alicloud_cidr" {
  destination_cidr_block = "${alicloud_vswitch.vsw2.cidr_block}"
  vpn_connection_id = "${aws_vpn_connection.ipsec1.id}"
}

# Alicloud
resource "alicloud_vpc" "vpc2" {
  name = "alicloud_vpc2"
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "vsw2" {
  name = "alicloud_vsw2"
  vpc_id = "${alicloud_vpc.vpc2.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "${var.zone2}"
}

resource "alicloud_vpn_gateway" "vgw2" {
  name = "vgw2"
  vpc_id = "${alicloud_vpc.vpc2.id}"
  bandwidth = "10"
  enable_ipsec = "true"
  instance_charge_type = "PostPaid"
  #vswitch_id = "${alicloud_vswitch.vsw2.id}"
}

resource "alicloud_vpn_customer_gateway" "vgw2_cgw1" {
  name = "vgw2_cgw1"
  ip_address = "${aws_vpn_connection.ipsec1.tunnel1_address}"
}

resource "alicloud_vpn_connection" "ipsec2" {
  name = "ipsec2"
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw2.id}"
  customer_gateway_id = "${alicloud_vpn_customer_gateway.vgw2_cgw1.id}"
  local_subnet = ["${alicloud_vswitch.vsw2.cidr_block}"]
  remote_subnet = ["${aws_subnet.subnet1.cidr_block}"]
  effect_immediately = true
  ike_config {
    ike_auth_alg = "sha1"
    ike_enc_alg = "aes"
    ike_version = "ikev2"
    ike_mode = "main"
    ike_lifetime = 86400
    psk = "aws_alicloud"
    ike_pfs = "group2"
    }
  ipsec_config {
    ipsec_pfs = "group2"
    ipsec_enc_alg = "aes"
    ipsec_auth_alg = "sha1"
    ipsec_lifetime = 86400
    }
}

/*
resource "alicloud_vpn_route_entry" "route2" {
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw2.id}"
  route_dest = "${aws_subnet.subnet1.cidr_block}"
  next_hop = "${alicloud_vpn_connection.ipsec2.id}"
  weight = 100
  publish_vpc = true
}
*/
