provider "azurerm" {
  features {}
}

#######################################################################
## Configuration for remote state, currently state is local
#######################################################################
terraform {
  backend "azurerm" {
    resource_group_name  = "permanent-rg"
    storage_account_name = "mrwterraformstate"
    container_name       = "terraform-state"
    key                  = "terraform-state-hub-spoke-app-gateway"
  }
}