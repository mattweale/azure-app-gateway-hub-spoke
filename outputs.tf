# Outputs
output "hub_firewall_public_ip_address" {
  value       = azurerm_public_ip.fw_pip.ip_address
  description = "The public IP address of the firewall"
}

output "hub_firewall_private_ip_address" {
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  description = "The private IP address of the firewall"
}

output "vm1_private_ip_address" {
  value       = azurerm_windows_virtual_machine.spoke_vm1.private_ip_address
  description = "The private IP address of virtual machine 1"
}

output "vm2_private_ip_address" {
  value       = azurerm_windows_virtual_machine.spoke_vm2.private_ip_address
  description = "The private IP address of virtual machine 2"
}

output "app_gateway_public_ip_address" {
  value       = azurerm_public_ip.app_gw_pip.ip_address
  description = "The public IP address of the app gateway"
}