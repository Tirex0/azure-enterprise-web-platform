resource "azurerm_resource_group" "sharedservicesRG" {
  name     = var.sharedservices_resource_group_name
  location = var.sharedservices_resource_group_location
}

resource "random_string" "sharedservicesStorageSuffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_storage_account" "sharedservicesStorage" {
  name                     = "tfstate${random_string.sharedservicesStorageSuffix.result}"
  resource_group_name      = azurerm_resource_group.sharedservicesRG.name
  location                 = azurerm_resource_group.sharedservicesRG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "terraform-state"
  storage_account_id    = azurerm_storage_account.sharedservicesStorage.id
  container_access_type = "private"
}
