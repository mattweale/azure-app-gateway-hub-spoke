#######################################################################
## Create Spoke vNET
#######################################################################
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "${var.prefix}spoke-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["172.17.0.0/16"]
  tags                = var.tags
}

#######################################################################
## Create Subnet in Spoke for Backend VMs
#######################################################################
resource "azurerm_subnet" "subnet_be" {
  name                 = "back-end-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["172.17.1.0/24"]
}

#######################################################################
## Create a VNet Peer between Spoke and Hub
#######################################################################
resource "azurerm_virtual_network_peering" "peer2" {
  name                         = "${var.prefix}spoke-hub-peer"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

#######################################################################
## Create NSG [and Associate] for Spoke Subnet
#######################################################################
resource "azurerm_network_security_group" "nsg_spoke" {
  name                = "${var.prefix}-spoke-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "rdp-in-a"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    destination_port_range     = "3389"
    source_address_prefix      = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
    destination_address_prefix = azurerm_network_interface.spoke_vm1_nic.private_ip_address
  }
  security_rule {
    name                       = "rdp-in-b"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3389"
    destination_port_range     = "3389"
    source_address_prefix      = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
    destination_address_prefix = azurerm_network_interface.spoke_vm2_nic.private_ip_address
  }
  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "assoc_nsg_spoke_subnet" {
  subnet_id                 = azurerm_subnet.subnet_be.id
  network_security_group_id = azurerm_network_security_group.nsg_spoke.id
}

#######################################################################
## Create route table for Spoke default route
#######################################################################
resource "azurerm_route_table" "local_default_route_table" {
  name                          = "${var.prefix}spoke-default-route-table"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
  tags = var.tags
}

#######################################################################
## Create Network Interface - Spoke VM1
#######################################################################

resource "azurerm_network_interface" "spoke_vm1_nic" {
  name                 = "spoke-vm-1-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "spoke-1-ipconfig"
    subnet_id                     = azurerm_subnet.subnet_be.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

#######################################################################
## Create Virtual Machine #1 in Spoke
#######################################################################

resource "azurerm_windows_virtual_machine" "spoke_vm1" {
  name                  = "spoke-vm-1"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.spoke_vm1_nic.id]
  size                  = var.vmsize
  computer_name         = "spoke-vm-1"
  admin_username        = var.username
  admin_password        = var.password
  provision_vm_agent    = true

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name                 = "spoke-vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  tags = var.tags
}

#######################################################################
## Create Network Interface - Spoke VM2
#######################################################################

resource "azurerm_network_interface" "spoke_vm2_nic" {
  name                 = "spoke-vm-2-nic"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "spoke-2-ipconfig"
    subnet_id                     = azurerm_subnet.subnet_be.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

#######################################################################
## Create Virtual Machine #2 in Spoke
#######################################################################

resource "azurerm_windows_virtual_machine" "spoke_vm2" {
  name                  = "spoke-vm-2"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.spoke_vm2_nic.id]
  size                  = var.vmsize
  computer_name         = "spoke-vm-2"
  admin_username        = var.username
  admin_password        = var.password
  provision_vm_agent    = true

  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    name                 = "spoke-vm2-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  tags = var.tags
}