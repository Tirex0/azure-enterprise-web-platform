output "backend_address_pool_id" {
  value = tolist(azurerm_application_gateway.network.backend_address_pool)[0].id
}

output "app_gateway_id" {
  description = "Application Gateway resource ID used by Azure Monitor."
  value       = azurerm_application_gateway.network.id
}

output "public_ip_address" {
  description = "Public IPv4 address of the Application Gateway."
  value       = azurerm_public_ip.app_gw_pip.ip_address
}
