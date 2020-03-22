# Region1's Provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region1}"
  alias = "alias1"
}

# Region2's Provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region2}"
  alias = "alias2"
}

resource "alicloud_vpc" "vpc1" {
  provider = "alicloud.alias1"
  name = "alicloud_vpc1"
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "vsw1" {
  provider = "alicloud.alias1"
  name = "alicloud_vsw1"
  vpc_id = "${alicloud_vpc.vpc1.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "${var.zone1}"
}

resource "alicloud_vpn_gateway" "vgw1" {
  provider = "alicloud.alias1"
  name = "vgw1"
  vpc_id = "${alicloud_vpc.vpc1.id}"
  bandwidth = "10"
  enable_ipsec = "true"
  instance_charge_type = "PostPaid"
  #vswitch_id = "${alicloud_vswitch.vsw1.id}"
}

resource "alicloud_vpn_customer_gateway" "vgw1_cgw1" {
  provider = "alicloud.alias1"
  name = "vgw1_cgw1"
  ip_address = "${alicloud_vpn_gateway.vgw2.internet_ip}"
}

resource "alicloud_vpn_connection" "ipsec1" {
  provider = "alicloud.alias1"
  name = "ipsec1"
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw1.id}"
  customer_gateway_id = "${alicloud_vpn_customer_gateway.vgw1_cgw1.id}"
  local_subnet = ["0.0.0.0/0"]
  remote_subnet = ["0.0.0.0/0"]
  effect_immediately = true
  ike_config {
    ike_auth_alg = "sha1"
    ike_enc_alg = "aes"
    ike_version = "ikev2"
    ike_mode = "main"
    ike_lifetime = 86400
    psk = "Alitest"
    ike_pfs = "group2"
    }
  ipsec_config {
    ipsec_pfs = "group2"
    ipsec_enc_alg = "aes"
    ipsec_auth_alg = "sha1"
    ipsec_lifetime = 86400
    }
}

resource "alicloud_vpn_route_entry" "route1" {
  provider = "alicloud.alias1"
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw1.id}"
  route_dest = "${alicloud_vswitch.vsw2.cidr_block}"
  next_hop = "${alicloud_vpn_connection.ipsec1.id}"
  weight = 100
  publish_vpc = true
}

resource "alicloud_vpc" "vpc2" {
  provider = "alicloud.alias2"
  name = "alicloud_vpc2"
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "vsw2" {
  provider = "alicloud.alias2"
  name = "alicloud_vsw2"
  vpc_id = "${alicloud_vpc.vpc2.id}"
  cidr_block = "172.16.1.0/24"
  availability_zone = "cn-shanghai-b"
}

resource "alicloud_vpn_gateway" "vgw2" {
  provider = "alicloud.alias2"
  name = "vgw2"
  vpc_id = "${alicloud_vpc.vpc2.id}"
  bandwidth = "10"
  enable_ipsec = "true"
  instance_charge_type = "PostPaid"
  #vswitch_id = "${alicloud_vswitch.vsw2.id}"
}
resource "alicloud_vpn_customer_gateway" "vgw2_cgw1" {
  provider = "alicloud.alias2"
  name = "vgw2_cgw1"
  ip_address = "${alicloud_vpn_gateway.vgw2.internet_ip}"
}

resource "alicloud_vpn_connection" "ipsec2" {
  provider = "alicloud.alias2"
  name = "ipsec2"
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw2.id}"
  customer_gateway_id = "${alicloud_vpn_customer_gateway.vgw2_cgw1.id}"
  local_subnet = ["0.0.0.0/0"]
  remote_subnet = ["0.0.0.0/0"]
  effect_immediately = true
  ike_config {
    ike_auth_alg = "sha1"
    ike_enc_alg = "aes"
    ike_version = "ikev2"
    ike_mode = "main"
    ike_lifetime = 86400
    psk = "Alitest"
    ike_pfs = "group2"
    }
  ipsec_config {
    ipsec_pfs = "group2"
    ipsec_enc_alg = "aes"
    ipsec_auth_alg = "sha1"
    ipsec_lifetime = 86400
    }
}

resource "alicloud_vpn_route_entry" "route2" {
  provider = "alicloud.alias2"
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw2.id}"
  route_dest = "${alicloud_vswitch.vsw1.cidr_block}"
  next_hop = "${alicloud_vpn_connection.ipsec2.id}"
  weight = 100
  publish_vpc = true
}
