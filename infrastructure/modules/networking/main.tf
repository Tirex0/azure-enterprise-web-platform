resource "azurerm_virtual_network" "enterprise_web_vnet" {
  name                = var.vnet_details["enterprise_web_vnet"].name
  address_space       = var.vnet_details["enterprise_web_vnet"].address_space
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnet_details
  name                 = each.value.name
  address_prefixes     = each.value.address_prefixes
  virtual_network_name = azurerm_virtual_network.enterprise_web_vnet.name
  resource_group_name  = var.resource_group_name
}


resource "azurerm_network_security_group" "subnet_nsgs" {

  for_each = var.nsg_rules

  name                = "${each.key}-nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {

    for_each = each.value

    content {

      name      = security_rule.key
      priority  = security_rule.value.priority
      direction = security_rule.value.direction
      access    = security_rule.value.access
      protocol  = security_rule.value.protocol

      source_address_prefix = security_rule.value.source_subnet != null ? (
        var.subnet_details[security_rule.value.source_subnet].address_prefixes[0]
      ) : security_rule.value.source_address_prefix

      source_port_range          = security_rule.value.source_port_range
      destination_address_prefix = security_rule.value.destination_address_prefix
      destination_port_range     = security_rule.value.destination_port_range
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each                  = var.subnet_details
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnet_nsgs[each.key].id
}


