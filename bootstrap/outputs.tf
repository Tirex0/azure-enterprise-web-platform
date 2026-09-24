output "resource_group_name" {
  value = azurerm_resource_group.sharedservicesRG.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sharedservicesStorage.name
}

output "storage_container_name" {
  value = azurerm_storage_container.terraform_state.name
}
