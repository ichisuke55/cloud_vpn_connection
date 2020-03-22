# Region1 outputs
output "vpc1" {
  value = ["${alicloud_vpc.vpc1.*.id}"]
}
output "vsw1" {
  value = ["${alicloud_vswitch.vsw1.id}"]
}
output "vgw1" {
  value = ["${alicloud_vpn_gateway.vgw1.id}"]
}
output "vgw1_cgw1" {
  value = ["${alicloud_vpn_customer_gateway.vgw1_cgw1.id}"]
}
output "ipsec1" {
  value = ["${alicloud_vpn_connection.ipsec1.id}"]
}
output "route1" {
  value = ["${alicloud_vpn_route_entry.route1.id}"]
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
output "route2" {
  value = ["${alicloud_vpn_route_entry.route2.id}"]
}
