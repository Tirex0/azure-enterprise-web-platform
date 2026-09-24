output "subnet_ids" {
  value = {
    for key, subnet in azurerm_subnet.subnets :
    key => subnet.id
  }
}
