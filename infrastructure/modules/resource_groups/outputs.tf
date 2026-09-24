output "resource_group_name" {
  value = { for key, rg in azurerm_resource_group.resource_groups : key => rg.name }
}

output "resource_group_location" {
  value = { for key, rg in azurerm_resource_group.resource_groups : key => rg.location }
}
