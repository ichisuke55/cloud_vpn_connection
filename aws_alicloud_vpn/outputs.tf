# Region1 outputs
output "vpc1" {
  value = ["${aws_vpc.vpc1.id}"]
}

output "subnet1" {
  value = ["${aws_subnet.subnet1.id}"]
}

output "vgw1" {
  value = ["${aws_vpn_gateway.vgw1.id}"]
}

output "vgw1_cgw1" {
  value = ["${aws_customer_gateway.vgw1_cgw1.id}"]
}

output "ipsec1" {
  value = ["${aws_vpn_connection.ipsec1.tunnel1_address}", "${aws_vpn_connection.ipsec1.tunnel2_address}"]
}

# Region2 outputs
output "vpc2" {
  value = ["${alicloud_vpc.vpc2.*.id}"]
}
output "vsw2" {
  value = ["${alicloud_vswitch.vsw2.id}"]
}
output "vgw2" {
  value = ["${alicloud_vpn_gateway.vgw2.id}"]
}
output "vgw2_cgw1" {
  value = ["${alicloud_vpn_customer_gateway.vgw2_cgw1.id}"]
}
output "ipsec2" {
  value = ["${alicloud_vpn_connection.ipsec2.id}"]
}
/*
output "route2" {
  value = ["${alicloud_vpn_route_entry.route2.id}"]
}
*/
