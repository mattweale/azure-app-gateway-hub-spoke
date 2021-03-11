##########################################################
## Install IIS role on VM #1 in Spoke
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-spoke-vm1" {

  name                 = "install-iis-spoke-1-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke_vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}

##########################################################
## Install IIS role on VM #2 in Spoke
##########################################################
resource "azurerm_virtual_machine_extension" "install-iis-spoke-vm2" {

  name                 = "install-iis-spoke-1-vm"
  virtual_machine_id   = azurerm_windows_virtual_machine.spoke_vm2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}