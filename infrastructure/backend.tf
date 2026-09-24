terraform {
  backend "azurerm" {
    resource_group_name  = "sharedservices-rg"
    storage_account_name = "tfstatec3h48"
    container_name       = "terraform-state"
    key                  = "dev.terraform.tfstate"
  }
}
