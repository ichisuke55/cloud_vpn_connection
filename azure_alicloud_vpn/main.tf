# Region1(Azure)'s Provider
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
}

# Region2(Alicloud)'s Provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region2}"
}

resource "azurerm_resource_group" "resource" {
  name = "vpn_connection_resource_sample"
  location = "${var.region1}"
}

resource "azurerm_virtual_network" "vnet" {
  name = "vnet"
  location = "${azurerm_resource_group.resource.location}"
  resource_group_name = "${azurerm_resource_group.resource.name}"
  address_space = ["172.16.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name = "GatewaySubnet"
  resource_group_name = "${azurerm_resource_group.resource.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix = "172.16.1.0/24"
}

resource "azurerm_local_network_gateway" "alicloud" {
  name = "vpn_alicloud"
  location = "${azurerm_resource_group.resource.location}"
  resource_group_name = "${azurerm_resource_group.resource.name}"
  gateway_address = "${alicloud_vpn_gateway.vgw2.internet_ip}"
  address_space = ["${alicloud_vswitch.vsw2.cidr_block}"]
}

resource "azurerm_public_ip" "pubip" {
  name = "pubip"
  location = "${azurerm_resource_group.resource.location}"
  resource_group_name = "${azurerm_resource_group.resource.name}"
  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vgw1" {
  name = "vgw1"
  location = "${azurerm_resource_group.resource.location}"
  resource_group_name = "${azurerm_resource_group.resource.name}"

  type = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp = false
  sku = "Basic"

  ip_configuration {
    name = "vnetGatewayConfig"
    public_ip_address_id = "${azurerm_public_ip.pubip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id = "${azurerm_subnet.subnet.id}"
  }
}

resource "azurerm_virtual_network_gateway_connection" "ipsec1" {
  name = "ipsec1"
  location = "${azurerm_resource_group.resource.location}"
  resource_group_name = "${azurerm_resource_group.resource.name}"

  type = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vgw1.id}"
  local_network_gateway_id = "${azurerm_local_network_gateway.alicloud.id}"
  
  shared_key = "azure_alicloud"
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
  ip_address = "${azurerm_public_ip.pubip.ip_address}"
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
    psk = "azure_alicloud"
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
  route_dest = "${azurerm_subnet.subnet.address_prefix}"
  next_hop = "${alicloud_vpn_connection.ipsec2.id}"
  weight = 100
  publish_vpc = true
}
