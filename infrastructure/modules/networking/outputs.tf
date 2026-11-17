output "subnet_ids" {
  value = {
    for key, subnet in azurerm_subnet.subnets :
    key => subnet.id
  }
}

output "workload_nat_public_ip" {
  description = "Stable outbound IP used by the web and application subnets."
  value       = azurerm_public_ip.workload_nat.ip_address
}
