# Region1(GCP)'s Provider
provider "google" {
  credentials = "${file("key.json")}"
  project = "${var.project_id}"
  region = "${var.region1}"
}

# Region2(Alicloud)'s Provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region2}"
}

# GCP
resource "google_compute_network" "vpc1" {
  name = "gcp2alicloud"
}

resource "google_compute_subnetwork" "subnet1" {
  name = "subnet1"
  ip_cidr_range = "172.16.1.0/24"
  network = "${google_compute_network.vpc1.name}"
  region = "${var.region1}"
}

resource "google_compute_address" "pubip" {
  name = "pubip"
}

resource "google_compute_vpn_gateway" "vgw1" {
  name = "vgw1"
  network = "${google_compute_network.vpc1.self_link}"
}

resource "google_compute_vpn_tunnel" "ipsec1" {
  name = "ipsec1"
  peer_ip = "${alicloud_vpn_gateway.vgw2.internet_ip}"
  shared_secret = "gcp_alicloud"

  target_vpn_gateway = "${google_compute_vpn_gateway.vgw1.self_link}"
  local_traffic_selector = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]
  ike_version = 2

  depends_on =  [
    "google_compute_forwarding_rule.esp",
    "google_compute_forwarding_rule.udp500",
    "google_compute_forwarding_rule.udp4500"
  ]
}

resource "google_compute_forwarding_rule" "esp" {
  name = "esp"
  ip_protocol = "ESP"
  ip_address = "${google_compute_address.pubip.address}"
  target = "${google_compute_vpn_gateway.vgw1.self_link}"
}

resource "google_compute_forwarding_rule" "udp500" {
  name = "udp500"
  ip_protocol = "UDP"
  port_range = "500"
  ip_address = "${google_compute_address.pubip.address}"
  target = "${google_compute_vpn_gateway.vgw1.self_link}"
}

resource "google_compute_forwarding_rule" "udp4500" {
  name = "udp4500"
  ip_protocol = "UDP"
  port_range = "4500"
  ip_address = "${google_compute_address.pubip.address}"
  target = "${google_compute_vpn_gateway.vgw1.self_link}"
}

resource "google_compute_route" "route1" {
  name = "route1"
  network = "${google_compute_network.vpc1.name}"
  dest_range = "${alicloud_vswitch.vsw2.cidr_block}"
  priority = 100

  next_hop_vpn_tunnel = "${google_compute_vpn_tunnel.ipsec1.self_link}"
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
  ip_address = "${google_compute_address.pubip.address}"
}

resource "alicloud_vpn_connection" "ipsec2" {
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
    psk = "gcp_alicloud"
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
  vpn_gateway_id = "${alicloud_vpn_gateway.vgw2.id}"
  route_dest = "${google_compute_subnetwork.subnet1.ip_cidr_range}"
  next_hop = "${alicloud_vpn_connection.ipsec2.id}"
  weight = 100
  publish_vpc = true
}
