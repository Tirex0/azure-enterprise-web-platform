output "app_vm_id" {
  value       = azurerm_linux_virtual_machine.app_vm.id
  description = "Resource ID of the application VM."
}

output "web_vmss_id" {
  value       = azurerm_linux_virtual_machine_scale_set.web_server_scale_set.id
  description = "Resource ID of the web VMSS."
}
