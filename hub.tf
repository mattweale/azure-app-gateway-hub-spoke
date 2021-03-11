#######################################################################
## Create Hub vNET
#######################################################################
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.prefix}hub-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["172.16.0.0/16"]
  tags                = var.tags
}

#######################################################################
## Create Subnet in Hub for Firewall
#######################################################################
resource "azurerm_subnet" "fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["172.16.1.0/24"]
}

#######################################################################
## Create Subnet in Hub for Application Gateway
#######################################################################
resource "azurerm_subnet" "app_gw_subnet" {
  name                 = "AppGatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["172.16.2.0/24"]
}

#######################################################################
## Firewall
#######################################################################
resource "azurerm_public_ip" "fw_pip" {
  name                = "${var.prefix}firewall-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.prefix}firewall"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  threat_intel_mode   = "Deny"

  ip_configuration {
    name                 = "firewall-ip-config"
    subnet_id            = azurerm_subnet.fw_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
  tags = var.tags
}

#######################################################################
## Add DNAT rule for RDP to VMs
#######################################################################
resource "azurerm_firewall_nat_rule_collection" "default_dnat" {
  name                = "${var.prefix}dnat-policy"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 110
  action              = "Dnat"

  rule {
    name                  = "rdp-in-vm1"
    source_addresses      = ["${var.source_ip}"]
    destination_ports     = ["8081"]
    destination_addresses = [azurerm_public_ip.fw_pip.ip_address]
    translated_port       = 3389
    translated_address    = azurerm_network_interface.spoke_vm1_nic.private_ip_address
    protocols             = ["TCP"]
  }
  rule {
    name                  = "rdp-in-vm2"
    source_addresses      = ["${var.source_ip}"]
    destination_ports     = ["8082"]
    destination_addresses = [azurerm_public_ip.fw_pip.ip_address]
    translated_port       = 3389
    translated_address    = azurerm_network_interface.spoke_vm2_nic.private_ip_address
    protocols             = ["TCP"]
  }
}

#######################################################################
## Create a VNet Peer between Hub and Spoke
#######################################################################
resource "azurerm_virtual_network_peering" "peer1" {
  name                         = "${var.prefix}hub-spoke-peer"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

#######################################################################
## Application Gateway
#######################################################################
resource "azurerm_public_ip" "app_gw_pip" {
  name                = "${var.prefix}app-gw-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_address_pool_name      = "${azurerm_virtual_network.hub_vnet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.hub_vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.hub_vnet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.hub_vnet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.hub_vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.hub_vnet.name}-rqrt"
  #redirect_configuration_name    = "${azurerm_virtual_network.hub_vnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "${var.prefix}app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "WAF_V2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gw_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gw_pip.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_windows_virtual_machine.spoke_vm1.private_ip_address, azurerm_windows_virtual_machine.spoke_vm2.private_ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    #path                  = "/"
    port            = 80
    protocol        = "Http"
    request_timeout = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

    request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  #Test Multi-Site Wildcard Listener and Rule
    frontend_port {
    name = "test-wildcard-fe-port"
    port = 8080
  }
  
  http_listener {
    name                           = "test-wildcard-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "test-wildcard-fe-port"
    protocol                       = "Http"
    host_names                     = ["*.gingerviz.com","*.flappypaddles.com"]
  }
   
  request_routing_rule {
    name                       = "test-wildcard-rule"
    rule_type                  = "Basic"
    http_listener_name         = "test-wildcard-listener"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

}