provider "azurerm" {
  features {}
}

#######################################################################
## Configuration for remote state, currently state is local
#######################################################################
#terraform {
#  backend "azurerm" {
#    resource_group_name  = ""
#    storage_account_name = ""
#    container_name       = ""
#    key                  = ""
#  }
#}